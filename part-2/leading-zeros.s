    .data

input_addr:      .word  0x80 
output_addr:     .word  0x84

    .text
_start:
    @p input_addr a! @          \ input -> T

    count_leading_zeros

    @p output_addr a! !         \ T -> output
    halt

shift_right_n:
    r>                          \ T -> R

shift_cycle:
    dup if end_shift
    2/                          \ T >> 1
    next shift_cycle
    ; 
    
end_shift: 
    >r drop ; 

count_leading_zeros:
    dup if zero                     \ if T == 0 then zero

    lit 30 r>                   \ 31 -> R
    lit 0 over                  \ 0 -> S
count_cycle:
    dup                         \ T -> T T
    >r dup r>                   \ R -> T
    shift_right_n               \ T >> i
    lit 1 and                   \ T & 1
    if count_plus               \ if T == 0 then cnt++
    over
    >r drop ;

count_plus:           
    over lit 1 + over                 \ cnt += 1
    next count_cycle            \ continue cycle
    over
    ;

zero:
    drop lit 32
    ;
