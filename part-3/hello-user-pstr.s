    .data

buf:                .byte   '________________________________'

str1:               .byte   7
str1_:              .byte   'Hello, '

str2:               .byte   1
str2_:              .byte   '!'

str3:               .byte   19
str3_:              .byte   'What is your name?\n'

input_addr:         .word   0x80
output_addr:        .word   0x84
eof:                .byte   '\n'
buf_start_addr:     .word   0x0
buf_size_bytes:     .word   0x20
overflow_value:     .word   0xCCCC_CCCC

    .text

_start:
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
    jal     ra, load_byte
    sub     s2, s2, a0
;----------------------------------------------------------------------------------------------------------
    lui     a0, %hi(str2)                       ; subtract str2 length from buffer size (s2)
    addi    a0, a0, %lo(str2)
    jal     ra, load_byte
    sub     s2, s2, a0
;----------------------------------------------------------------------------------------------------------
    addi    s2, s2, -1                          ; substract 1 from buffer size (s2) because 
                                                ; we need one byte to store length
;----------------------------------------------------------------------------------------------------------
    lui     s3, %hi(output_addr)                ; load output address into s3
    addi    s3, s3, %lo(output_addr)
    lw      s3, 0(s3)
;----------------------------------------------------------------------------------------------------------
    lui     a0, %hi(str3)                       ; print str3
    addi    a0, a0, %lo(str3)
    mv      a1, s3 
    jal     ra, print_pstr
;----------------------------------------------------------------------------------------------------------
    addi    a0, zero, 0                         ; store zero to first buffer byte (now it is empty pstr)
    mv      a1, s1
    jal     ra, store_byte
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; add str1 to buffer
    lui     a1, %hi(str1) 
    addi    a1, a1, %lo(str1)
    jal     ra, concate_pstrs                   ; after call a0 is ptr to first free element in buffer
;----------------------------------------------------------------------------------------------------------
    lui     a1, %hi(input_addr)                 ; load input address into a1
    addi    a1, a1, %lo(input_addr)
    lw      a1, 0(a1)

    lui     a2, %hi(eof)                        ; load eof symbol into a2
    addi    a2, a2, %lo(eof)
    lw      a2, 0(a2)

    mv      a3, s2                              ; load left buffer size into a3

    jal     ra, read_data
;----------------------------------------------------------------------------------------------------------
    addi    t0, zero, -1                        ; if a0 is -1 that goto overflow
    beq     a0, t0, overflow
;----------------------------------------------------------------------------------------------------------
    mv      s4, a0                              ; store received str length (a0) to s4 (to save it after call)

    mv      a0, s1                              ; load size of current string in buffer (s1) in a0     
    jal     ra, load_byte

    add     a0, a0, s4                          ; sum received string length (s4) and current length (a0)

    mv      a1, s1                              ; store new str len (a0) into first symbol of buffer (s1)
    jal     ra, store_byte
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; load buffer start ptr into a0

    lui     a1, %hi(str2)                       ; load str2 ptr into a1
    addi    a1, a1, %lo(str2)

    jal     ra, concate_pstrs                   ; concatenate str2 and string in buffer
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; print buffer string
    mv      a1, s3
    jal     ra, print_pstr
;----------------------------------------------------------------------------------------------------------
    halt

;###########################################################################################################

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
;   a0 -> number of received symbols or -1 in case of overflow

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

    beq     a0, s2, ret_read_data               ; if received symbol is eof then return

    mv      a1, s0                              ; store received symbol in buffer
    sw      ra, 20(sp)
    jal     ra, store_byte
    lw      ra, 20(sp)

    addi    s0, s0, 1                           ; increase buffer ptr
    addi    s4, s4, 1                           ; increase symbol counter

    j       read_data_cycle                     ; continue cycle
;----------------------------------------------------------------------------------------------------------
read_data_overflow:
    addi    s4, zero, -1                        ; write -1 to symbol counter
;----------------------------------------------------------------------------------------------------------
ret_read_data:
    mv      a0, s4                              ; write number of received symbols (s4) to return (a0)

    lw      s0, 0(sp)                           ; restore callee saved registers                 
    lw      s1, 4(sp)
    lw      s2, 8(sp)
    lw      s3, 12(sp)
    lw      s4, 16(sp)
    addi    sp, sp, 32

    jr      ra                                  ; return

;###########################################################################################################

; Print pascal string

; arguments
;   a0 -> ptr to pstr
;   a1 -> output address

print_pstr:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -16                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
    mv      s1, a1
;----------------------------------------------------------------------------------------------------------
    sw      ra, 8(sp)                           ; load string length and save it in t0
    jal     ra, load_byte
    lw      ra, 8(sp)
    mv      t0, a0
;----------------------------------------------------------------------------------------------------------
    addi    s0, s0, 1                           ; move ptr because we don't print str length
;----------------------------------------------------------------------------------------------------------
;   t0 -> number of symbols left
;   s0 -> ptr to current symbol
;   s1 -> ptr to output register
;----------------------------------------------------------------------------------------------------------
print_cycle:
    beqz    t0, ret_print_pstr                  ; if no symbols left then return          
    addi    t0, t0, -1                          ; else decrease t0

    lw      t1, 0(s0)                           ; load word from cur ptr
    sb      t1, 0(s1)                           ; print lower byte into output

    addi    s0, s0, 1                           ; increase ptr

    j       print_cycle                         ; continue cycle
;----------------------------------------------------------------------------------------------------------
ret_print_pstr:
    lw      s0, 0(sp)                           ; restore callee saved registers
    lw      s1, 4(sp)
    addi    sp, sp, 16

    jr      ra                                  ; return

;###########################################################################################################

; Add one pascal string to another
; pstr1 += pstr2
; Legth is updated automatically

; argumemts
;   a0 -> ptr to pstr1
;   a1 -> ptr to pstr2

; return
;   a0 -> ptr to sybmol after end of pstr1
concate_pstrs:
;----------------------------------------------------------------------------------------------------------
    addi    sp, sp, -16                         ; save callee saved registers into stack
    sw      s0, 0(sp)
    sw      s1, 4(sp)
    sw      s2, 8(sp)
;----------------------------------------------------------------------------------------------------------
    mv      s0, a0                              ; move arguments to callee saved registers
    mv      s1, a1
;----------------------------------------------------------------------------------------------------------
    mv      a0, s1                              ; load length of pstr2 to s2
    sw      ra, 12(sp)                  
    jal     ra, load_byte
    lw      ra, 12(sp)
    mv      s2, a0
;----------------------------------------------------------------------------------------------------------
    mv      a0, s0                              ; load length of pstr1 to a0
    sw      ra, 12(sp)
    jal     ra, load_byte
    lw      ra, 12(sp)

    mv      t0, s0                              ; save ptr to pstr1 start (s0) into t0 (just tmp)

    add     s0, s0, a0                          ; move prt to pstr1 to the element after end
    addi    s0, s0, 1                           ; by adding it's length + 1
;----------------------------------------------------------------------------------------------------------
    add     a0, a0, s2                          ; strore total length of pstr1 (a0) and pstr2 (s2)  
    mv      a1, t0                              ; into pstr1 start (t0)
    sw      ra, 12(sp)
    jal     ra, store_byte
    lw      ra, 12(sp)
;----------------------------------------------------------------------------------------------------------
    addi    s1, s1, 1                           ; skip first byte with size in pstr2
;----------------------------------------------------------------------------------------------------------
;   s0 -> ptr to pstr1
;   s1 -> ptr to pstr2
;   s2 -> number of symbols left in pstr2
;----------------------------------------------------------------------------------------------------------
concate_cycle:
    beqz    s2, ret_concate_pstrs               ; if no symbols left is pstr2, return
    addi    s2, s2, -1                          ; else decrease number of left symbols

    lw      a0, 0(s1)                           ; load current symbol from pstr2 and save it into current ptr in pstr1
    mv      a1, s0
    sw      ra, 12(sp)
    jal     ra, store_byte
    lw      ra, 12(sp)

    addi    s0, s0, 1                           ; increase ptrs
    addi    s1, s1, 1

    j       concate_cycle                       ; continue cycle
;----------------------------------------------------------------------------------------------------------
ret_concate_pstrs:
    mv      a0, s0                              ; write prt to symbol after end of pstr1 (s0) in return (a0)

    lw      s0, 0(sp)                           ; restore callee saved registers
    lw      s1, 4(sp)
    lw      s2, 8(sp)
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