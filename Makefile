ARCH=x86_64

OBJS=kernel.o
TARGET=BOOTX64.efi
BINARY_PATH=BOOTX64.efi
CC=gcc

# Paths to GNU-EFI source
EFI_SRC=gnu-efi-src/gnuefi
EFI_LIB_DIR=gnu-efi-src/x86_64/lib
EFI_INC_DIR=gnu-efi-src/inc
EFI_LIB_DIR2=gnu-efi-src/lib
# Compiler flags
EFI_INCLUDES=-I$(EFI_INC_DIR) -I$(EFI_INC_DIR)/$(ARCH) -I$(EFI_INC_DIR)/protocol
CFLAGS=$(EFI_INCLUDES) -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER

# Linker flags
EFI_CRT_OBJS=$(EFI_SRC)/crt0-efi-$(ARCH).o
EFI_LDS=$(EFI_SRC)/elf_$(ARCH)_efi.lds
LDFLAGS=-nostdlib -T $(EFI_LDS) -shared -Bsymbolic $(EFI_CRT_OBJS) \
        $(EFI_LIB_DIR)/libefi.a $(EFI_LIB_DIR2)/libgnuefi.a

all: $(TARGET)

# Build the EFI binary
$(TARGET): $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@

# Compile C files
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

# Convert .so to .efi (optional)
%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
	        -j .dynsym -j .rel -j .rela -j .reloc \
	        --target=efi-app-$(ARCH) $^ $@

# Create EFI image (optional)
image:
	dd if=/dev/zero of=/tmp/part.img bs=512 count=91669
	mformat -i /tmp/part.img -h 32 -t 32 -n 64 -c 1
	mcopy -i /tmp/part.img ${BINARY_PATH} ::app.efi
	echo app.efi > startup.nsh
	mcopy -i /tmp/part.img startup.nsh ::/
	dd if=/dev/zero of=${DISK_PATH} bs=512 count=93750
	parted ${DISK_PATH} -s -a minimal mklabel gpt
	parted ${DISK_PATH} -s -a minimal mkpart EFI FAT16 2048s 93716s
	parted ${DISK_PATH} -s -a minimal toggle 1 boot
	dd if=/tmp/part.img of=${DISK_PATH} bs=512 count=91669 seek=2048 conv=notrunc

# Clean build files
clean:
	rm -f *.so *.o *.efi
