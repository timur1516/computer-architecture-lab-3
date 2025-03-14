    .data

buf:                .byte   '________________________________'
buf_start:          .word   0x0
i:                  .word   0x0
ptr:                .word   0x0
intput_addr:        .word   0x80
output_addr:        .word   0x84
buf_size:           .word   0x20
eof:                .word   0xA
cap_case_shift:     .word   32
space:              .word   0x20
const_a:            .word   'a'
const_z:            .word   'z'
const_A:            .word   'A'
const_Z:            .word   'Z'

const_1:            .word   1
const_0:            .word   0
const_FF:           .word   0xFF
mask:               .word   0xFFFFFF00
overflow_value:     .word   0xCCCC_CCCC

cap_flag:           .word   1
tmp:                .word   0x0

    .text

_start:

    load_addr       buf_start                   ; buf_start + 1 -> ptr
    add             const_1
    store_addr      ptr

    load_addr       const_0                     ; 0 -> i
    store_addr      i

read_cycle:
    sub             buf_size                    ; if i == buf_size: overflow
    beqz            overflow

    load_ind        intput_addr                 ; lower byte of input -> tmp
    and             const_FF
    store_addr      tmp

    load_addr       eof                         ; if tmp == eof: store_str_len
    sub             tmp
    beqz            store_str_len

    load_addr       space                       ; if tmp == space: set_cap_flag
    sub             tmp
    beqz            set_cap_flag

    load_addr       cap_flag                    ; if !cap_flag: to_lowercase
    beqz            to_lowercase
                                                ; else: to_uppercase
to_uppercase:                                   
    load_addr       tmp                         ; if tmp < 'a': goto remove_cap_flag
    sub             const_a                     
    ble             remove_cap_flag

    load_addr       const_z                     ; if tmp > 'z': goto remove_cap_flag
    sub             tmp
    ble             remove_cap_flag

    load_addr       tmp                         ; convert to uppercase
    sub             cap_case_shift
    store_addr      tmp

remove_cap_flag:
    load_addr       const_0                     ; 0 -> cap_flag
    store_addr      cap_flag
    
    jmp             store_tmp                   ; goto store_tmp                                 

to_lowercase:
    load_addr       tmp                         ; if tmp < 'A': goto store_tmp
    sub             const_A                     
    ble             store_tmp

    load_addr       const_Z                     ; if tmp > 'Z': goto store_tmp
    sub             tmp
    ble             store_tmp

    load_addr       tmp                         ; convert to lowercase
    add             cap_case_shift
    store_addr      tmp

    jmp             store_tmp                   ; goto store_tmp

set_cap_flag:
    load_addr       const_1                     ; 1 -> cap_flag
    store_addr      cap_flag

store_tmp:
    load_ind        ptr                         ; tmp -> M[ptr]
    and             mask
    or              tmp
    store_ind       ptr

    load_addr       ptr                         ; ptr++
    add             const_1
    store_addr      ptr

    load_addr       i                           ; i++
    add             const_1
    store_addr      i

    jmp             read_cycle                  ; continue cycle

store_str_len:
    load_ind        buf_start                   ; i -> M[buf_start]
    and             mask
    or              i
    store_ind       buf_start

    load_addr       buf_start                   ; buf_start + 1 -> ptr
    add             const_1
    store_addr      ptr    

    load_addr       i                           ; i -> acc

print_cycle:
    beqz            end                         ; if i == 0: goto end

    load_ind        ptr                         ; cout << lower byte of M[ptr]
    and             const_FF
    store_ind       output_addr

    load_addr       ptr                         ; ptr++
    add             const_1
    store_addr      ptr

    load_addr       i                           ; i--
    sub             const_1                    
    store_addr      i

    jmp             print_cycle                 ; continue cycle

end:
    halt

overflow:
    load_addr       overflow_value
    store_ind       output_addr
    halt
