ARCH=x86_64

OBJS=kernel.o
TARGET=BOOTX64.efi
BINARY_PATH=BOOTX64.efi
DISK_PATH=./HamzaOS.iso
CC=gcc


# Paths to GNU-EFI source
EFI_SRC=gnu-efi-src/gnuefi
EFI_LIB_DIR=gnu-efi-src/x86_64/lib
EFI_INC_DIR=gnu-efi-src/inc
EFI_LIB_DIR2=gnu-efi-src/x86_64/gnuefi
# Compiler flags
EFI_INCLUDES=-I$(EFI_INC_DIR) -I$(EFI_INC_DIR)/$(ARCH) -I$(EFI_INC_DIR)/protocol
CFLAGS=$(EFI_INCLUDES) -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER

# Linker flags
EFI_CRT_OBJS=$(EFI_SRC)/crt0-efi-$(ARCH).o
EFI_LDS=$(EFI_SRC)/elf_$(ARCH)_efi.lds
LDFLAGS=gnu-efi-src/gnuefi/elf_x86_64_efi.lds -shared -Bsymbolic gnu-efi-src/gnuefi/crt0-efi-x86_64.o gnu-efi-src/x86_64/lib/libefi.a gnu-efi-src/x86_64/gnuefi//libgnuefi.a

# Default target
all: $(TARGET)

# Build BOOTX64.efi directly from object files
$(TARGET): $(OBJS)
	ld $(LDFLAGS) $(OBJS) -o $@



# Compile C files
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

# Optional: create a FAT image for EFI
image:
	mkdir -p iso_root/EFI/BOOT
	cp BOOTX64.efi iso_root/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs \
		-o HamzaOS.iso \
  		-iso-level 3 \
		-volid "HAMZAOS" \
		-eltorito-alt-boot \
		-e EFI/BOOT/BOOTX64.EFI \
		-no-emul-boot \
		-isohybrid-gpt-basdat \
 		iso_root


	
