; Test Fase 1a multiciclo: NOP, LI, J, JZ, JNZ
; Comprueba el flujo basico del autómata sin tocar ALU/MEM.
;
; Tras ejecutarse se esperan estos valores:
;   r1 = 10
;   r2 = 20
;   r3 = 0    (nunca escrito - salto J lo evita)
;   r4 = 30
;   r5 = 40
;   r6 = 0    (nunca escrito - JNZ lo evita)
;   PC bloqueado en la etiqueta fin

        li    10, r1          ; r1 = 10
        li    20, r2          ; r2 = 20
        j     skip            ; saltar a skip, addr 4
        li    99, r3           ; NO debe ejecutarse
skip:   li    30, r4           ; r4 = 30
        jz    fin              ; Z=0 al inicio, NO debe saltar
        li    40, r5           ; r5 = 40
        jnz   fin              ; Z=0, SI debe saltar
        li    99, r6           ; NO debe ejecutarse
fin:    nop
        j     fin              ; bucle
