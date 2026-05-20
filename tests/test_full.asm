; Test completo: todas las instrucciones con nueva codificación
; Verifica retrocompatibilidad + nuevas instrucciones

; --- Carga de valores ---
        li    10, r1          ; R1 = 10
        li    3, r2           ; R2 = 3

; --- ALU reg-reg ---
        add   r1, r2, r3     ; R3 = 13
        sub   r1, r2, r4     ; R4 = 7
        and   r1, r2, r5     ; R5 = 2
        or    r1, r2, r6     ; R6 = 11
        mov   r1, r7         ; R7 = 10
        not   r1, r8         ; R8 = ~10
        neg   r1, r9         ; R9 = -10

; --- ALU inmediato ---
        addi  r1, 5, r10     ; R10 = 15
        subi  r1, 3, r11     ; R11 = 7
        andi  r1, 6, r12     ; R12 = 2
        ori   r1, 5, r13     ; R13 = 15

; --- LOAD/STORE ---
        li    100, r14       ; R14 = 100 (base)
        store r1, r14, 0     ; MEM[100] = 10
        load  r15, r14, 0    ; R15 = MEM[100] = 10

; --- CALL/RET ---
        call  subr           ; llama a subrutina
        j     fin            ; tras volver, salta a fin

subr:   li    99, r1         ; R1 = 99
        ret                  ; vuelve

; --- Interrupciones ---
fin:    ei                   ; habilitar interrupciones
        di                   ; deshabilitar
        nop
        j     fin            ; bucle final