; Test: bucle con STORE como en init_memo
; Llena mem[10..14] con 0 (5 posiciones)
;
; Esperado:
;   r5 = 15 (10 + 5)
;   r6 = 0
;   r9 = 99 (post-bucle)
;   mem[10] = mem[11] = ... = mem[14] = 0

        li    10, r5
        li    5, r6
loop:
        store r0, r5, 0
        addi  r5, 1, r5
        subi  r6, 1, r6
        jnz   loop
        li    99, r9
fin:    j     fin
