    .data

buf:                .byte   '________________________________'

str1:               .byte   'Hello, '
str1_null:          .byte   0

str2:               .byte   '!'
str2_null:          .byte   0

str3:               .byte   'What is your name?\n'
str3_null:          .byte   0

input_addr:         .word   0x80
output_addr:        .word   0x84
eof:                .word   0xA
buf_start_addr:     .word   0x0
buf_size_bytes:     .word   0x20
overflow_value:     .word   0xCCCC_CCCC
init_sp_value:      .word   0x1000  

    .text
    .org 0x100
_start:
    lui     sp, %hi(init_sp_value)              ; load init value of stack pointer
    addi    sp, sp, %lo(init_sp_value)
    lw      sp, 0(sp)
;----------------------------------------------------------------------------------------------------------
    lui     s1, %hi(buf_start_addr)             ; load buffer start address into s1
    addi    s1, s1, %lo(buf_start_addr)
    lw      s1, 0(s1)
;----------------------------------------------------------------------------------------------------------
    lui     s2, %hi(buf_size_bytes)             ; load buffer size into s2
    addi    s2, s2, %lo(buf_size_bytes)
    lw      s2, 0(s2)
;----------------------------------------------------------------------------------------------------------
    lui     a0, %hi(str1)                       ; subtract str1 length from buffer size (s2)
    addi    a0, a0, %lo(str1)
    jal     ra, get_len_cstr
    sub     s2, s2, a0
;----------------------------------------------------------------------------------------------------------
    lui     a0, %hi(str2)                       ; subtract str2 length from buffer size (s2)
    addi    a0, a0, %lo(str2)
    jal     ra, get_len_cstr
    sub     s2, s2, a0
;----------------------------------------------------------------------------------------------------------
    addi    s2, s2, -1                          ; substract 1 from buffer size (s2) because 
                                                ; we need one byte with null terminator
;----------------------------------------------------------------------------------------------------------
    lui     s3, %hi(output_addr)                ; load output address into s3
    addi    s3, s3, %lo(output_addr)
    lw      s3, 0(s3)
;----------------------------------------------------------------------------------------------------------
    lui     a0, %hi(str3)                       ; print str3
    addi    a0, a0, %lo(str3)
    mv      a1, s3 
    jal     ra, print_cstr
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; copy str1 into buffer
    lui     a1, %hi(str1) 
    addi    a1, a1, %lo(str1)
    jal     ra, copy_cstr                       ; after call a0 is ptr to null terminator in buffer
;----------------------------------------------------------------------------------------------------------
    lui     a1, %hi(input_addr)                 ; load input address into a1
    addi    a1, a1, %lo(input_addr)
    lw      a1, 0(a1)

    lui     a2, %hi(eof)                        ; load eof symbol into a2
    addi    a2, a2, %lo(eof)
    lw      a2, 0(a2)

    mv      a3, s2                              ; load left buffer size into a3

    jal     ra, read_data                       ; read data from input address and save it into buffer
                                                ; after call a0 is ptr to null terminator in buffer
                                                ; or -1 in case of overflow
;----------------------------------------------------------------------------------------------------------
    addi    t0, zero, -1                        ; if a0 is -1 than goto overflow
    beq     a0, t0, overflow
;----------------------------------------------------------------------------------------------------------
    lui     a1, %hi(str2)                       ; copy str2 into buffer
    addi    a1, a1, %lo(str2)
    jal     ra, copy_cstr
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; print buffer string
    mv      a1, s3
    jal     ra, print_cstr
;----------------------------------------------------------------------------------------------------------
    halt
;----------------------------------------------------------------------------------------------------------
overflow:
    lui     t0, %hi(overflow_value)             ; load overflow value into t0
    addi    t0, t0, %lo(overflow_value)
    lw      t0, 0(t0)         

    sw      t0, 0(s3)                           ; print t0

    halt

;###########################################################################################################

; Read data from input address and save into bufer
; Reading stops when eof symbol reached or buffer is full

; arguments
;   a0 -> buffer ptr
;   a1 -> input address
;   a2 -> eof
;   a3 -> buffer size

; return
;   a0 -> ptr to null terminator in buffer or -1 in case of overflow

read_data:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -32                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
    sw      s2, 8(sp)
    sw      s3, 12(sp)
    sw      s4, 16(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
    mv      s1, a1
    mv      s2, a2
    mv      s3, a3

    addi    s4, zero, 0                         ; init symbol counter (s4)
;----------------------------------------------------------------------------------------------------------
;   s0 -> ptr to current position in buffer
;   s1 -> ptr to input register
;   s2 -> eof symbol
;   s3 -> buffer length
;   s4 -> number of received symbols
;----------------------------------------------------------------------------------------------------------
read_data_cycle:
    beq     s3, s4, read_data_overflow          ; if buffer is full then goto read_data_overflow
    
    lw      a0, 0(s1)                           ; read new sybmol

    beq     a0, s2, append_null                 ; if received symbol is eof then return
    beqz    a0, read_left_cycle                 ; if received symbol is zero then read left without storing

    mv      a1, s0                              ; store received symbol in buffer
    sw      ra, 20(sp)
    jal     ra, store_byte
    lw      ra, 20(sp)

    addi    s0, s0, 1                           ; increase buffer ptr
    addi    s4, s4, 1                           ; increase symbol counter

    j       read_data_cycle                     ; continue cycle
;----------------------------------------------------------------------------------------------------------
read_data_overflow:
    addi    s0, zero, -1                        ; write -1 to s0 to indicate overflow
    j       ret_read_data                       ; return
;----------------------------------------------------------------------------------------------------------
read_left_cycle:
    lw      a0, 0(s1)                           ; read new sybmol
    beq     a0, s2, append_null                 ; if received symbol is eof then return
    j       read_left_cycle                     ; continue cycle
;----------------------------------------------------------------------------------------------------------
append_null:
    addi    a0, zero, 0                         ; store null terminator in buffer
    mv      a1, s0
    sw      ra, 20(sp)
    jal     ra, store_byte
    lw      ra, 20(sp)
;----------------------------------------------------------------------------------------------------------
ret_read_data:  
    mv      a0, s0                              ; write ptr to null terminator (s0) to return (a0)

    lw      s0, 0(sp)                           ; restore callee saved registers                 
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    lw      s3, 12(sp)
    lw      s4, 16(sp)
    addi    sp, sp, 32

    jr      ra                                  ; return

;###########################################################################################################

; Print C string

; arguments
;   a0 -> ptr to cstr
;   a1 -> output address

print_cstr:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -16                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
    mv      s1, a1
;----------------------------------------------------------------------------------------------------------
;   s0 -> ptr to current symbol
;   s1 -> ptr to output register
;----------------------------------------------------------------------------------------------------------
print_cycle:
    mv      a0, s0                              ; load current symbol from cstr
    sw      ra, 8(sp)
    jal     ra, load_byte
    lw      ra, 8(sp)

    beqz    a0, ret_print_cstr                  ; if symbol is zero then return

    sb      a0, 0(s1)                           ; print symbol into output

    addi    s0, s0, 1                           ; increase ptr

    j       print_cycle                         ; continue cycle
;----------------------------------------------------------------------------------------------------------
ret_print_cstr:
    lw      s0, 0(sp)                           ; restore callee saved registers
    lw      s1, 4(sp)
    addi    sp, sp, 16

    jr      ra                                  ; return

;###########################################################################################################

; Copy C string into buffer

; argumemts
;   a0 -> ptr buffer
;   a1 -> ptr to cstr

; return
;   a0 -> ptr to null terminator after end of cstr in buffer
copy_cstr:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -16                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
    mv      s1, a1
;----------------------------------------------------------------------------------------------------------
;   s0 -> ptr to buffer
;   s1 -> ptr to cstr2
;----------------------------------------------------------------------------------------------------------
copy_cycle:
    mv      a0, s1                              ; load current symbol from cstr
    sw      ra, 8(sp)
    jal     ra, load_byte
    lw      ra, 8(sp)
    
    beqz    a0, ret_copy_cstr                   ; if symbol is zero then return

    mv      a1, s0                              ; store symbol in buffer      
    sw      ra, 8(sp)
    jal     ra, store_byte
    lw      ra, 8(sp)

    addi    s0, s0, 1                           ; increase ptrs
    addi    s1, s1, 1

    j       copy_cycle                          ; continue cycle
;----------------------------------------------------------------------------------------------------------
ret_copy_cstr:
    addi    a0, zero, 0                         ; store null terminator in buffer after cstr   
    mv      a1, s0     
    sw      ra, 8(sp)
    jal     ra, store_byte
    lw      ra, 8(sp)

    mv      a0, s0                              ; write prt to cstr null terminator (s0) in return (a0)

    lw      s0, 0(sp)                           ; restore callee saved registers
    lw      s1, 4(sp)
    addi    sp, sp, 16

    jr      ra                                  ; return

;###########################################################################################################

; Get length of C string

; arguments
;   a0 -> ptr to cstr

; return
;   a0 -> length of cstr
get_len_cstr:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -16                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
;----------------------------------------------------------------------------------------------------------
    addi    s1, zero, 0                         ; init length counter (s1)
;----------------------------------------------------------------------------------------------------------
;   s0 -> ptr to current symbol
;   s1 -> length counter
;----------------------------------------------------------------------------------------------------------
get_len_cycle:
    mv      a0, s0                              ; load current symbol from cstr
    sw      ra, 8(sp)
    jal     ra, load_byte
    lw      ra, 8(sp)
    mv      t0, a0

    beqz    t0, ret_get_len_cstr                ; if symbol is zero then return

    addi    s0, s0, 1                           ; increase ptr
    addi    s1, s1, 1                           ; increase length counter

    j       get_len_cycle                         ; continue cycle
;----------------------------------------------------------------------------------------------------------
ret_get_len_cstr:
    mv      a0, s1                              ; write length counter (s1) to return (a0)
    
    lw      s0, 0(sp)                           ; restore callee saved registers
    lw      s1, 4(sp)
    addi    sp, sp, 16

    jr      ra                                  ; return

;###########################################################################################################

; Load lower byte from given address

; arguments
;   a0 -> address

; return
;   a0 -> loaded byte

load_byte:
    lw      a0, 0(a0)                           ; load from memory
    addi    t0, zero, 0xff                      ; init mask 0x000000ff
    and     a0, a0, t0                          ; apply mask
    jr      ra                                  ; return

;###########################################################################################################

; Store lower byte to given address
; The point is that the other bytes of the word don't change

; arguments
;   a0 -> data to store
;   a1 -> address

store_byte:
    lw      t0, 0(a1)                           ; M[a1] -> t0

    addi    t1, zero, 8                         ; 0xffffff00 -> t2
    addi    t2, zero, -1
    sll     t2, t2, t1

    addi    t3, zero, 0xff                      ; 0x000000ff -> t3

    and     t0, t0, t2                          ; apply mask1 to clear lower byte in t0
    and     a0, a0, t3                          ; apply mask2 to clear everything except of lower byte in a0
    or      t0, t0, a0                          ; update byte
    sw      t0, 0(a1)                           ; t0 -> M[a1]
    jr      ra                                  ; return

;##################################################################################