; Test: LOAD seguido de AND y JZ (patron del knapsack)
;
; mem[5] = 0x02 (1 << 1 = bit 1)
; load r4 = mem[5] = 2
; li 2, r5 -> r5 = 2
; and r4, r5, r6 -> r6 = 2&2 = 2, Z=0
; jz skip -> NO debe saltar (Z=0)
; li 77, r7 -> debe ejecutar -> r7 = 77
;
; Despues:
; mem[6] = 0
; load r4 = mem[6] = 0
; li 2, r5
; and r4, r5, r6 -> r6 = 0&2 = 0, Z=1
; jz fin -> SI debe saltar
; li 88, r8 -> NO debe ejecutar -> r8 = 0

        li    5, r1
        li    2, r4
        store r4, r1, 0           ; mem[5] = 2
        li    6, r1
        li    0, r4
        store r4, r1, 0           ; mem[6] = 0

        nop
        nop
        nop
        nop

        ; --- patron 1: Z=0, jz no salta ---
        li    5, r1
        load  r4, r1, 0           ; r4 = 2
        li    2, r5
        and   r4, r5, r6          ; r6 = 2, Z=0
        jz    bad                 ; NO debe saltar
        li    77, r7              ; r7 = 77

        nop
        nop
        nop
        nop

        ; --- patron 2: Z=1, jz salta ---
        li    6, r1
        load  r4, r1, 0           ; r4 = 0
        li    2, r5
        and   r4, r5, r6          ; r6 = 0, Z=1
        jz    fin                 ; SI debe saltar
        li    88, r8              ; NO debe ejecutar

bad:    li    99, r9              ; marcador de error
fin:    nop
        j     fin
