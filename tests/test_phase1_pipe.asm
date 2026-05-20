; Test Fase 1 pipeline (sin hazard handling).
;
; En Fase 1 no hay forwarding, ni stalls, ni flush en saltos. Por
; tanto el programa de test:
;   * NO usa saltos condicionales intermedios (necesitarian flush)
;   * Separa instrucciones con dependencias con >=4 NOPs (el WB
;     ocurre 4 ciclos despues del ID, hay que esperar a que el
;     valor este en el banco antes de leerlo)
;
; Verifica: LI inmediatas, NOP, ALU reg-reg, ALU reg-imm.

; --- Cargas iniciales ---
        li    10, r1            ; r1 = 10
        li    20, r2            ; r2 = 20
        li    25, r3            ; r3 = 25
        nop
        nop
        nop
        nop

; --- ALU reg-reg ---
        add   r1, r2, r4        ; r4 = 30
        nop
        nop
        nop
        nop

        add   r4, r3, r5        ; r5 = 55
        nop
        nop
        nop
        nop

; --- ALU reg-imm ---
        addi  r1, 5, r6         ; r6 = 15
        nop
        nop
        nop
        nop

        andi  r2, 12, r7        ; r7 = 20 & 12 = 4
        nop
        nop
        nop
        nop

; --- Bucle final ---
fin:    j     fin
