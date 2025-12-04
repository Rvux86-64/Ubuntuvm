#include "/usr/include/efi/efi.h"
#include "/usr/include/efi/efilib.h"
EFI_STATUS EFIAPI
efi_main (EFI_HANDLE image_handle, EFI_SYSTEM_TABLE* system_table)
{
    InitializeLib(image_handle, system_table);
    Print((CHAR16*)L"Hello from the UEFI\n");
    return EFI_SUCCESS;
}
