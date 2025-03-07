    .data

input_addr:      .word  0x80            \ input address
output_addr:     .word  0x84            \ output address
mask:            .word  0x80000000      \ bitmask

    .text
_start:
    @p input_addr a! @                  \ dataStack.push(mem[mem[input_addr]])

    count_leading_zeros 

    @p output_addr a! !                 \ mem[mem[output_addr]] <- dataStack.pop()
    halt

count_leading_zeros:
    dup if zero                         \ if dataStack.top() == 0 then goto zero
    
    lit 0                               \ dataStack.push(0)
    over                                \ swap(T, S)

count_cycle:
    dup                                 \ dataStack.push(dataStack.top())
    
    @p mask                             \ dataStack.push(mem[mask])
    and                                 \ dataStack.push(dataStack.pop() & dataStack.pop())  
    
    if continue                         \ if dataStack.top() == 0 then goto continue
    end ;                               \ else goto end  

continue:
    over lit 1 + over                   \ S += 1
    
    @p mask                             \ mem[mask] >> 1
    2/
    !p mask

    count_cycle ;                       \ goto count_cycle

end:
    over ;                              \ swap(T, S); return

zero:
    lit 32 ;                            \ dataStack.push(32); return

