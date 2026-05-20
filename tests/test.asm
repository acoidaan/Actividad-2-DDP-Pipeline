; Test completo paso 2: ALU inmediato + retrocompatibilidad
; Cada instruccion tiene el resultado esperado en comentario

; --- Carga de valores base ---
        li    10, r1          ; R1 = 10
        li    3, r2           ; R2 = 3

; --- Test ALU con inmediato ---
        addi  r1, 7, r3      ; R3 = 10 + 7 = 17
        addi  r1, 0, r4      ; R4 = 10 + 0 = 10 (caso borde)
        subi  r1, 4, r5      ; R5 = 10 - 4 = 6
        subi  r3, 17, r6     ; R6 = 17 - 17 = 0, Z=1
        andi  r1, 6, r7      ; R7 = 1010 & 0110 = 0010 = 2
        andi  r1, 15, r8     ; R8 = 1010 & 1111 = 1010 = 10
        ori   r1, 5, r9      ; R9 = 1010 | 0101 = 1111 = 15
        ori   r2, 12, r10    ; R10 = 0011 | 1100 = 1111 = 15

; --- Test retrocompatibilidad reg-reg ---
        add   r1, r2, r11    ; R11 = 10 + 3 = 13
        sub   r1, r2, r12    ; R12 = 10 - 3 = 7
        and   r1, r2, r13    ; R13 = 1010 & 0011 = 0010 = 2
        or    r1, r2, r14    ; R14 = 1010 | 0011 = 1011 = 11
        mov   r1, r15        ; R15 = 10

; --- Test salto con Z del subi ---
        subi  r1, 10, r6     ; R6 = 0, Z=1
        jz    ok             ; debe saltar
        li    255, r1        ; NO debe ejecutarse

ok:     j     ok             ; bucle final