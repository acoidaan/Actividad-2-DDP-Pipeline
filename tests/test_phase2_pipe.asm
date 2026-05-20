; Test Fase 2 pipeline: forwarding ALU
;
; Las instrucciones tienen dependencias RAW inmediatas que solo
; pueden resolverse con forwarding (EX/MEM->EX y MEM/WB->EX).
;
; Esperado al final:
;   r1=5, r2=10, r3=15, r4=30, r5=45, r6=2, r7=26

        li    5, r1              ; r1 = 5
        li    10, r2             ; r2 = 10
        add   r1, r2, r3         ; r3 = 15   (forward EX/MEM->EX desde li r2)
        add   r3, r3, r4         ; r4 = 30   (forward EX/MEM->EX desde add r3)
        add   r4, r3, r5         ; r5 = 45   (forward MEM/WB->EX desde r3, EX/MEM->EX desde r4)
        subi  r5, 43, r6         ; r6 = 2    (forward EX/MEM->EX desde r5)
        ori   r2, 16, r7         ; r7 = 26... espera: 10 | 16 = 26
        nop
        nop
        nop
        nop
fin:    j     fin
