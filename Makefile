
ARCH=x86_64

OBJS=kernel.o
TARGET=main.efi

CC=gcc

EFI_INCLUDE_PATH=/usr/local/include/efi
EFI_INCLUDES=-I$(EFI_INCLUDE_PATH) -I$(EFI_INCLUDE_PATH)/$(ARCH) -I$(EFI_INCLUDE_PATH)/protocol

CFLAGS=$(EFI_INCLUDES) -fno-stack-protector -fpic \
		  -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER

LIB_PATH=/usr/local/lib
EFI_LIB_PATH=/usr/local/lib/
EFI_CRT_OBJS=$(EFI_LIB_PATH)/crt0-efi-$(ARCH).o
EFI_LDS=$(EFI_LIB_PATH)/elf_$(ARCH)_efi.lds

LDFLAGS=-nostdlib -T $(EFI_LDS) -shared \
	  	-Bsymbolic -L $(EFI_LIB_PATH) -L $(LIB_PATH) $(EFI_CRT_OBJS) 

all: $(TARGET)

main.so: $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@ -lefi -lgnuefi

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
			-j .dynsym  -j .rel -j .rela -j .reloc \
			--target=efi-app-$(ARCH) $^ $@

clean:
	rm *.so *.o *.efi
