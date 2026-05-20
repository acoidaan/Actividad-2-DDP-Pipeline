; Test de interrupciones
; Vector de interrupción en 0x010 (dirección 16)

; addr 0: saltar al programa principal
        j     main

; addr 1-15: padding con NOPs hasta llegar a 0x010
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

; ==============================
; ISR en dirección 0x010 (= 16)
; ==============================
isr:    addi  r10, 1, r10     ; incrementar contador de interrupciones
        reti                  ; volver + reactivar IE

; ==============================
; Programa principal
; ==============================
main:   li    0, r10          ; R10 = contador de interrupciones
        li    0, r1           ; R1 = contador de ciclos
        ei                    ; habilitar interrupciones
loop:   addi  r1, 1, r1      ; R1++
        j     loop            ; bucle infinito