section .data:
    codes:  dd  0x6CC, 0x66C, 0x666, 0x498, 0x48C, 0x44C, 0x4C8, 0x4C4, 0x464, 0x648,
            dd  0x644, 0x624, 0x59C, 0x4DC, 0x4CE, 0x5CC, 0x4EC, 0x4E6, 0x672, 0x65C,
            dd  0x64E, 0x6E4, 0x674, 0x76E, 0x74C, 0x72C, 0x726, 0x764, 0x734, 0x732,
            dd  0x6D8, 0x6C6, 0x636, 0x518, 0x458, 0x446, 0x588, 0x468, 0x462, 0x688,
            dd  0x628, 0x622, 0x5B8, 0x58E, 0x46E, 0x5D8, 0x5C6, 0x476, 0x776, 0x68E,
            dd  0x62E, 0x6E8, 0x6E2, 0x6EE, 0x758, 0x746, 0x716, 0x768, 0x762, 0x71A,
            dd  0x77A, 0x642, 0x78A, 0x530, 0x50C, 0x4B0, 0x486, 0x42C, 0x426, 0x590,
            dd  0x584, 0x4D0, 0x4C2, 0x434, 0x432, 0x612, 0x650, 0x7BA, 0x614, 0x47A,
            dd  0x53C, 0x4BC, 0x49E, 0x5E4, 0x4F4, 0x4F2, 0x7A4, 0x794, 0x792, 0x6DE,
            dd  0x6F6, 0x7B6, 0x578, 0x51E, 0x45E, 0x5E8, 0x5E2, 0x7A8, 0x7A2, 0x5DE,
            dd  0x5EE, 0x75E, 0x7AE, 0x684, 0x690, 0x69C, 0x18EB

    msg:    db "The result = %d",10,0

    current_checksum    dw  0
    last_component      dw  0       ;character value * its number in order
    last_char_value     dw  0
    current_char_number dw  0       ;number of characters already decoded from the barcode

    black_address       dw  0

    %define     black_start [ebp-4]
    %define     smallest_width [ebp-8]

section .text:
global  decode
extern  printf
decode:
    push    ebp
    mov     ebp, esp
    sub     esp, 4

    push    ebx
    push    edx
    push    esi
    push    ecx

    mov     esi, [ebp+8]
    xor     ecx, ecx

prepare:
    add     esi, 43200
look_for_black:
    cmp     BYTE [esi], 0
    je      black_found
    cmp     ecx, 599
    ;cmp     ecx, max_skips
    je      no_barcode
    add     esi, 3
    inc     ecx
    jmp     look_for_black

black_found:
    mov     black_start, esi
    ;mov     [black_address], esi
    ;mov     black_start, esi
    xor     ecx, ecx
    ;mov     eax, 2137
    ;jmp     exit

calculate_width:
    cmp     BYTE [esi], 0
    jne     width_found
    inc     ecx
    add     esi, 3
    jmp     calculate_width

width_found:
    xor     edx, edx
    mov     eax, ecx
    mov     ecx, 2
    div     ecx
    sub     esp, 8
    mov     smallest_width, eax
    jmp     exit

no_barcode:
    mov     eax, 1488

exit:
    pop    ecx
    pop    esi
    pop    edx
    pop    ebx

    mov    esp, ebp
    pop    ebp
    ret