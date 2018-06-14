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
    

    %define     black_start             [ebp-4]
    %define     smallest_width          [ebp-8]
    %define     output                  [ebp-12]
    %define     line_to_read            [ebp-16]
    %define     bytes_to_skip           [ebp-20]
    %define     pattern                 [ebp-24]
    %define     number_of_shifts        [ebp-28]
    %define     current_color           [ebp-32]

    %define     char_counter            [ebp-36]
    %define     last_char_value         [ebp-40]
    %define     last_checksum_component [ebp-44]
    %define     current_checksum        [ebp-48]

    %define     address_holder          [ebp-52]


section .text:
global  decode
extern  printf
decode:
    push    ebp
    mov     ebp, esp
    sub     esp, 52

    push    ecx
    push    ebx
    ;push    edx
    push    esi
    push    edi

    xor     eax, eax
    mov     char_counter, eax
    mov     last_char_value, eax
    mov     last_checksum_component, eax
    mov     current_checksum, eax
    mov     address_holder, eax

    mov     esi, [ebp+8]
    mov     eax, [ebp+12]
    mov     line_to_read, eax
    mov     eax, [ebp+16]
    mov     output, eax
    xor     ecx, ecx

prepare:
    mov     ebx, line_to_read
    mov     eax, 1800
    mul     ebx
    mov     bytes_to_skip, eax
    add     esi, bytes_to_skip

;looking for the first occurence of the black pixel in a specified row    
look_for_black:
    cmp     BYTE [esi], 0
    je      black_found
    cmp     ecx, 599
    je      no_barcode
    add     esi, 3
    inc     ecx
    jmp     look_for_black

;we store addres of a first black pixel 
black_found:
    mov     black_start, esi
    xor     ecx, ecx

;we check the width of the first bar to calculate it's relative width (refering to the narrowest bar in the set)
calculate_width:
    cmp     BYTE [esi], 0
    jne     width_found
    inc     ecx
    cmp     ecx, 20
    je      too_wide
    add     esi, 3
    jmp     calculate_width

width_found:
    mov     eax, ecx
    mov     ecx, 2
    div     ecx
    mov     smallest_width, eax
    mov     esi, black_start

pre_prepare:
    xor     eax, eax
    mov     pattern, eax
    mov     number_of_shifts, eax

prepare_bar_reading:
    xor     ecx, ecx
    movzx   eax, BYTE [esi]
    mov     current_color, eax

;reading bar = smallest width of the bar in set
get_bar:
    movzx   eax, BYTE [esi]
    inc     ecx
    add     esi, 3
    cmp     ecx, smallest_width
    je      bar_obtained
    jmp     get_bar

bar_obtained:
    mov     eax, current_color
    cmp     eax, 0x00000000
    je      black_bar

;if color == black we do current_pattern | 1, else current_pattern_ | 0, we do like this 11 times to get full patern
white_bar:
    mov     eax, pattern
    or      eax, 0
    mov     pattern, eax
    mov     eax, number_of_shifts
    inc     eax
    cmp     eax, 11
    je      pattern_finished    ;todo: change to pattern finished
    mov     number_of_shifts, eax
    mov     eax, pattern
    shl      eax, 1
    mov     pattern, eax
    jmp     prepare_bar_reading

black_bar:
    mov     eax, pattern
    or      eax, 1
    mov     pattern, eax
    mov     eax, number_of_shifts
    inc     eax
    cmp     eax, 11
    je      pattern_finished    ;todo: change to pattern finished
    mov     number_of_shifts, eax
    mov     eax, pattern
    shl     eax, 1
    mov     pattern, eax
    jmp     prepare_bar_reading

pattern_finished:
    mov     number_of_shifts, eax
    mov     eax, pattern
    mov     address_holder, esi
    xor     ecx, ecx
    mov     esi, codes

;after we do 11 logical operations, we look at the array if our pattern is present 
compare:
    mov     ebx, [esi + ecx * 4]
    cmp     eax, ebx
    je      equal

not_equal:
    inc     ecx
    cmp     ecx, 106
    je      possible_stop
    jmp     compare

equal:
    cmp     ecx, 103
    je      start
    cmp     ecx, 104
    je      wrong_set
    cmp     ecx, 105
    je      wrong_set
    mov     eax, char_counter
    inc     eax
    mov     char_counter, eax
    mov     last_char_value, ecx
    mul     ecx
    mov     last_checksum_component, eax
    add     eax, current_checksum
    mov     current_checksum, eax
    mov     eax, last_char_value
    add     eax, 32
    mov     edi, output
    mov     [edi], eax
    inc     edi
    mov     output, edi
    mov     esi, address_holder
    jmp     pre_prepare

start:
    mov     current_checksum, ecx
    mov     esi, address_holder
    jmp     pre_prepare

;if not, we assume that our pattern may be stop code (only one which need 2 additional bits (13 summary) to be encoded)
possible_stop:
    xor     eax, eax
    mov     number_of_shifts, eax
    mov     esi, address_holder

;we get 2 additional bars
get_bars:
    movzx   eax, BYTE [esi]
    mov     current_color, eax
    xor     ecx, ecx

get_additional_bar:
    movzx   eax, BYTE [esi]
    inc     ecx
    add     esi, 3
    cmp     ecx, smallest_width
    je      additional_bar_obtained
    jmp     get_additional_bar

additional_bar_obtained:
    mov     eax, current_color
    cmp     eax, 0x00000000
    je      black_bar_obtained

white_bar_obtained:
    mov     eax, pattern
    shl     eax, 1
    or      eax, 0
    mov     pattern, eax
    mov     eax, number_of_shifts
    inc     eax
    cmp     eax, 2
    je      finalize
    mov     number_of_shifts, eax
    jmp     get_bars

black_bar_obtained:
    mov     eax, pattern
    shl     eax, 1
    or      eax, 1
    mov     pattern, eax
    mov     eax, number_of_shifts
    inc     eax
    cmp     eax, 2
    je      finalize
    mov     number_of_shifts, eax
    jmp     get_bars

;if after getting 2 additional bars our pattern doesn't match stop code, we assume error - wrong code
finalize:
    mov     address_holder, esi
    mov     esi, codes
    mov     ecx, 106
    mov     ebx, [esi + ecx * 4]
    mov     eax, pattern
    cmp     eax, ebx
    je      match

wrong_code:
    mov     eax, 5
    jmp     exit

;else, we check if stop - 1 character (checksum value) was encoded correctly
;to do so, we assume 1 char before stop is actual checksum
;we manualy calculate sum of all other characters * their position in the sequence
;we perform obtained_sum % 103
;if out outcome == checksum_value, we validate encoding and printf outcome
;else we assume error - wrong checksum value
match:
    mov     eax, current_checksum
    mov     ebx, last_checksum_component
    sub     eax, ebx
    mov     ebx, 103
    div     ebx
    cmp     edx, last_char_value
    je      exit_succes

wrong_checksum:
    mov     eax, 4
    jmp     exit

too_wide:
    mov     eax, 2
    jmp     exit

wrong_set:
    mov     eax, 3
    jmp     exit

no_barcode:
    mov     eax, 1
    jmp     exit

exit_succes:
    mov     edi, output
    dec     edi
    mov     BYTE [edi], 0
    mov     eax, 0

exit:
    pop    edi
    pop    esi
    ;pop    edx
    pop    ebx
    pop    ecx

    mov    esp, ebp
    pop    ebp
    ret