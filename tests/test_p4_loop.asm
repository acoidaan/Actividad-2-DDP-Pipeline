; Test bucle simple: decrementar r1 hasta 0
; Iteraciones: r1=5, 4, 3, 2, 1, 0 (sale del bucle)
; Esperado: r1=0, r2 incrementado 5 veces = 5, r3=99 (post-bucle)

        li    5, r1
        li    0, r2
loop:
        addi  r2, 1, r2
        subi  r1, 1, r1
        jnz   loop
        li    99, r3
fin:    j     fin
