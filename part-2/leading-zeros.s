    .data

input_addr:      .word  0x80 
output_addr:     .word  0x84
mask:            .word  0x80000000

    .text
_start:
    @p input_addr a! @

    count_leading_zeros

    @p output_addr a! !
    halt

count_leading_zeros:
    dup if zero
    lit 0
    over

count_cycle:
    dup
    @p mask
    and
    if continue
    end ;
continue:
    over lit 1 + over
    @p mask
    2/
    !p mask
    count_cycle ;
end:
    over ;

zero:
    lit 32 ;

