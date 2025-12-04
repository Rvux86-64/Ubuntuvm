ARCH=x86_64

OBJS=kernel.o
TARGET=BOOTX64.efi
BINARY_PATH=BOOTX64.efi
CC=gcc

# Use GNU-EFI from downloaded source directory
EFI_SRC=gnu-efi-src/gnuefi

EFI_INCLUDE_PATH=gnu-efi-src/inc
EFI_INCLUDES=-I$(EFI_INCLUDE_PATH) \
             -I$(EFI_INCLUDE_PATH)/$(ARCH) \
             -I$(EFI_INCLUDE_PATH)/protocol

EFI_CRT_OBJS=$(EFI_SRC)/crt0-efi-$(ARCH).o
EFI_LDS=$(EFI_SRC)/elf_$(ARCH)_efi.lds

EFI_LIB_PATH=$(EFI_SRC)
LIB_PATH=$(EFI_SRC)

CFLAGS=$(EFI_INCLUDES) -fno-stack-protector -fpic \
       -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER

LDFLAGS=-nostdlib -T $(EFI_LDS) -shared \
        -Bsymbolic -L $(EFI_LIB_PATH) -L $(LIB_PATH) $(EFI_CRT_OBJS)

all: $(TARGET)

BOOTX64.so: $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@ -lefi -lgnuefi

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
	        -j .dynsym -j .rel -j .rela -j .reloc \
	        --target=efi-app-$(ARCH) $^ $@

image:
	## prepare files for efi partition (application binary + startup script)
	dd if=/dev/zero of=/tmp/part.img bs=512 count=91669
	mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1

	mcopy -i /tmp/part.img ${BINARY_PATH} ::app.efi
	echo app.efi > startup.nsh
	mcopy -i /tmp/part.img startup.nsh ::/

	## make full image (with format and efi partition)
	dd if=/dev/zero of=${DISK_PATH} bs=512 count=93750
	parted ${DISK_PATH} -s -a minimal mklabel gpt
	parted ${DISK_PATH} -s -a minimal mkpart EFI FAT16 2048s 93716s
	parted ${DISK_PATH} -s -a minimal toggle 1 boot
	## copy files into the image
	dd if=/tmp/part.img of=${DISK_PATH} bs=512 count=91669 seek=2048 conv=notrunc

clean:
	rm -f *.so *.o *.efi
