; Test simple de CALL/RET en pipeline
;
; Esperado:
;   r1=10, r2=20, r3=30 (despues de llamar a suma)
;   r4=99 (despues de RET, se ejecuta lo de despues de CALL)

        li    10, r1
        li    20, r2
        nop
        nop
        nop
        call  suma            ; r3 = r1+r2 = 30
        li    99, r4          ; despues del RET
        nop
        nop
        nop
fin:    j     fin

suma:   add   r1, r2, r3
        ret
