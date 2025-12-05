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
EFI_LIB_DIR2=gnu-efi-src/x86_64/gnuefi/
# Compiler flags
EFI_INCLUDES=-I$(EFI_INC_DIR) -I$(EFI_INC_DIR)/$(ARCH) -I$(EFI_INC_DIR)/protocol
CFLAGS=$(EFI_INCLUDES) -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -Wall -DEFI_FUNCTION_WRAPPER

# Linker flags
EFI_CRT_OBJS=$(EFI_SRC)/crt0-efi-$(ARCH).o
EFI_LDS=$(EFI_SRC)/elf_$(ARCH)_efi.lds
LDFLAGS=-nostdlib -T $(EFI_LDS)  -Bsymbolic $(EFI_CRT_OBJS) \
        $(EFI_LIB_DIR)/libefi.a $(EFI_LIB_DIR2)/libgnuefi.a -shared


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
	# Make FAT16 image
	dd if=/dev/zero of=ESP.img bs=1M count=50
	sudo mkfs.vfat -F 16 ESP.img
	sudo mkdir -p mnt
	sudo sudo mount -o loop ESP.img mnt
	sudo mkdir -p mnt/EFI/BOOT
	sudo cp BOOTX64.efi mnt/EFI/BOOT/BOOTX64.efi
	sudo umount mnt

	# Make ISO
	sudo xorriso -as mkisofs \
		-b EFI/BOOT/BOOTX64.EFI \
  		-no-emul-boot \
  		-efi-boot-part \
  		-efi-boot-image \
  		-o HamzaOS.iso ESP.img


# Clean build files
clean:
	rm -f *.o 
