; Test Fase 3 pipeline: LOAD/STORE + stall LOAD-use
;
; Sintaxis: las instrucciones ALU son  op fuente1, fuente2, destino
;           load  destino, base, desp
;           store fuente, base, desp
;
; Programa:
;   1. Carga 100 en r1, 5 en r2
;   2. store r1, r2, 0 -> mem[5] = 100
;   3. load r3, r2, 0  -> r3 = mem[5] = 100
;   4. add r3, r3, r4  -> r4 = r3+r3 = 200  (LOAD-use! requiere STALL)
;   5. addi r3, 1, r5  -> r5 = r3+1 = 101   (forward MEM/WB->EX)

        li    100, r1
        li    5, r2
        store r1, r2, 0
        load  r3, r2, 0
        add   r3, r3, r4
        addi  r3, 1, r5
        nop
        nop
        nop
        nop
fin:    j     fin
