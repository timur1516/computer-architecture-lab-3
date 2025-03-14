    .data

buf:                .byte   '________________________________'

str1_len:           .byte   7
str1:               .byte   'Hello, '
str2_len:           .byte   1
str2:               .byte   '!'
str3_len:           .byte   19
str3:               .byte   'What is your name?\n'

input_addr:         .word   0x80
output_addr:        .word   0x84
eof:                .byte   '\n'
buf_start_addr:     .word   0x0
buf_size_bytes:     .word   0x20
overflow_value:     .word   0xCCCC_CCCC

    .text

_start:
;----------------------------------------------------------------------------------
    lui     s0, %hi(input_addr)
    addi    s0, s0, %lo(input_addr)
    lw      s0, 0(s0)

    lui     s1, %hi(buf_start_addr)
    addi    s1, s1, %lo(buf_start_addr)
    lw      s1, 0(s1)

    lui     s2, %hi(buf_size_bytes)
    addi    s2, s2, %lo(buf_size_bytes)
    lw      s2, 0(s2)

    lui     s3, %hi(output_addr)
    addi    s3, s3, %lo(output_addr)
    lw      s3, 0(s3)
;----------------------------------------------------------------------------------
    lui     a0, %hi(str3_len)                       ; print(What is your name?\n)
    addi    a0, a0, %lo(str3_len)
    mv      a1, s3
    jal     ra, print_pstr
;----------------------------------------------------------------------------------
    lui     a0, %hi(str1_len)
    addi    a0, a0, %lo(str1_len)
    mv      a1, s1
    jal     ra, pstr_to_buffer
    sub     s2, s2, a0
    addi    s2, s2, -1
;----------------------------------------------------------------------------------
    mv      a1, s0

    lui     a2, %hi(eof)
    addi    a2, a2, %lo(eof)
    lw      a2, 0(a2)

    mv      a3, s2

    jal     ra, read_data
    addi    t0, zero, -1
    beq     a0, t0, overflow

    addi    s4, a0, -1
    mv      a0, s1
    jal     ra, load_byte
    add     a0, a0, s4
    mv      a1, s1
    jal     ra, store_byte
;----------------------------------------------------------------------------------
    mv      a0, s1
    lui     a1, %hi(str2_len)
    addi    a1, a1, %lo(str2_len)
    jal     ra, concate_pstrs
;----------------------------------------------------------------------------------
    mv      a0, s1
    mv      a1, s3
    jal     ra, print_pstr
;----------------------------------------------------------------------------------
    halt

overflow:
    lui     t0, %hi(overflow_value)
    addi    t0, t0, %lo(overflow_value)
    lw      t0, 0(t0)
    sw      t0, 0(s3)
    halt
;##################################################################################

; arguments
;   a0 -> buffer ptr
;   a1 -> input address
;   a2 -> eof
;   a3 -> buffer size
; return
;   a0 -> number of received symbols
read_data:
    addi    sp, sp, -32
    sw      s0, 0(sp)
    sw      s1, 4(sp)
    sw      s2, 8(sp)
    sw      s3, 12(sp)
    sw      s4, 16(sp)

    mv      s0, a0
    mv      s1, a1
    mv      s2, a2
    mv      s3, a3
    addi    s4, zero, 0

read_data_cycle:
    addi    s4, s4, 1

    lw      a0, 0(s1)

    beq     s3, s4, check_overflow
    beq     a0, s2, ret_read_data

    mv      a1, s0
    sw      ra, 20(sp)
    jal     ra, store_byte
    lw      ra, 20(sp)

    addi    s0, s0, 1

    j       read_data_cycle

check_overflow:
    beq     a0, s2, ret_read_data
    addi    s4, zero, -1
ret_read_data:
    mv      a0, s4
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    lw      s3, 12(sp)
    lw      s4, 16(sp)
    addi    sp, sp, 32
    jr      ra

;##################################################################################

; arguments
;   a0 -> ptr to pstr
;   a1 -> output address
print_pstr:
    addi    sp, sp, -16
    sw      s0, 0(sp)
    sw      s1, 4(sp)

    mv      s0, a0
    mv      s1, a1

    sw      ra, 8(sp)
    jal     ra, load_byte
    lw      ra, 8(sp)
    mv      t0, a0

    addi    s0, s0, 1

print_cycle:
    beqz    t0, ret_print_pstr
    addi    t0, t0, -1

    lw      t1, 0(s0)
    sb      t1, 0(s1)

    addi    s0, s0, 1
    j       print_cycle

ret_print_pstr:
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    addi    sp, sp, 16
    jr      ra

;##################################################################################

; arguments
;   a0 -> ptr to pstr
;   a1 -> ptr to buffer
; return
;   a0 -> new ptr in buffer
pstr_to_buffer:
    addi    sp, sp, -16
    sw      s0, 0(sp)
    sw      s1, 4(sp)
    sw      s2, 8(sp)

    mv      s0, a0
    mv      s1, a1

    sw      ra, 12(sp)
    jal     ra, load_byte
    lw      ra, 12(sp)

    addi    s2, a0, 1

copy_cycle:
    beqz    s2, ret_pstr_to_buffer
    addi    s2, s2, -1

    lw      a0, 0(s0)
    mv      a1, s1
    sw      ra, 12(sp)
    jal     ra, store_byte
    lw      ra, 12(sp)

    addi    s0, s0, 1
    addi    s1, s1, 1
    j       copy_cycle

ret_pstr_to_buffer:
    mv      a0, s1
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    addi    sp, sp, 16
    jr      ra

;##################################################################################

; argumemts
;   a0 -> ptr to pstr1
;   a1 -> ptr to pstr2
concate_pstrs:
    addi    sp, sp, -16                 ; init stack frame
    sw      s0, 0(sp)
    sw      s1, 4(sp)
    sw      s2, 8(sp)

    mv      s0, a0                      ; load args
    mv      s1, a1

    mv      a0, s1                      ; load size of pstr2
    sw      ra, 12(sp)                  
    jal     ra, load_byte
    lw      ra, 12(sp)

    mv      s2, a0                      ; save size of pstr2 to s2

    mv      a0, s0                      ; load size of pstr1
    sw      ra, 12(sp)
    jal     ra, load_byte
    lw      ra, 12(sp)

    mv      t0, s0                      ; save s0 to t0

    add     s0, s0, a0                  ; move pstr1 ptr to element after end
    addi    s0, s0, 1

    add     a0, a0, s2                  ; add size of pstr1 to size of pstr2 and save result in a0
    mv      a1, t0                      ; save sum to M[s0] (begining of pstr1)
    sw      ra, 12(sp)
    jal     ra, store_byte
    lw      ra, 12(sp)

    addi    s1, s1, 1                   ; skip size bytes in pstr2

concate_cycle:
    beqz    s2, ret_concate_pstrs
    addi    s2, s2, -1

    lw      a0, 0(s1)
    mv      a1, s0
    sw      ra, 12(sp)
    jal     ra, store_byte
    lw      ra, 12(sp)

    addi    s0, s0, 1
    addi    s1, s1, 1
    j       concate_cycle

ret_concate_pstrs:
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    addi    sp, sp, 16
    jr      ra

;##################################################################################

; arguments
;   a0 -> address
; return
;   a0 -> loaded byte
load_byte:
    lw      a0, 0(a0)               ; M[a0] -> a0
    addi    t0, zero, 0xff          ; 0x000000ff -> t0
    and     a0, a0, t0              ; apply mask
    jr      ra

;##################################################################################

; arguments
;   a0 -> data to store
;   a1 -> address
store_byte:
    lw      t0, 0(a1)               ; M[a1] -> t0

    addi    t1, zero, 8             ; 0xffffff00 -> t2
    addi    t2, zero, -1
    sll     t2, t2, t1

    addi    t3, zero, 0xff          ; 0x000000ff -> t3

    and     t0, t0, t2              ; apply mask1
    and     a0, a0, t3              ; apply mask2
    or      t0, t0, a0              ; update byte
    sw      t0, 0(a1)               ; t0 -> M[a1]
    jr      ra                      ; return

;##################################################################################