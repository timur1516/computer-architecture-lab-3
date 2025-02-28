    .data

input_addr:      .word  0x80               ; Input address
output_addr:     .word  0x84               ; Output address
a:               .word  0x00               ; value a
b:               .word  0x01               ; value b
tmp:             .word  0x02               ; tmp value for swap
minus_one:       .word  -1                 ; -1 value for sign change

    .text

_start:
    load_ind     input_addr                  ; cin >> a
    store        a

    load_ind     input_addr                  ; cin >> b
    store        b

while:
    load         b                           ; if b == 0 then break
    beqz         end

    store        tmp                         ; tmp = b

    load         a                           ; b = a % b
    rem          b
    store        b

    load         tmp                         ; a = tmp
    store        a

    jmp          while                       ; continue cycle

end:
    load         a                           ; if a > 0 then store ans
    bgt          store_ans

abs:
    mul          minus_one                   ; a *= -1
    bvs          overflow                    ; if overflow then overflow

store_ans:
    store_ind    output_addr                 ; cout << a
    halt

overflow:
    load_imm     0xCCCC_CCCC                 ; cout >> 0xCCCC_CCCC
    store_ind    output_addr
    halt

