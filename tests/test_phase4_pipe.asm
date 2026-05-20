; Test Fase 4 pipeline: saltos basicos con flush
;
; Esperado:
;   r1 = 10, r2 = 20, r3 = 0 (salto J saltó), r4 = 40,
;   r5 = 0 (JNZ saltó), r6 = 0 (nunca tocado)

        li    10, r1
        li    20, r2
        j     skip
        li    99, r3           ; fantasma, debe ser flusheada
        li    98, r3           ; fantasma, debe ser flusheada
skip:   li    40, r4
        nop
        nop
        nop
        subi  r4, 40, r5       ; r5=0, Z=1
        jz    fin              ; debe saltar
        li    99, r5           ; fantasma
        li    98, r5           ; fantasma
fin:    nop
        j     fin
