; Test completo: timer con interrupción
; El timer dispara cada 10 ciclos, la ISR incrementa
; un contador y lo muestra en LEDR

        j     main

; Padding hasta 0x010
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
; ISR en 0x010
; ==============================
isr:    addi  r10, 1, r10          ; R10++ (contador de IRQs)
        store r10, r14, 2          ; LEDR = R10 (dir 0x0402)
        reti

; ==============================
; Programa principal
; ==============================
main:   li    0x0400, r14          ; r14 = base periféricos
        li    0, r10               ; r10 = contador IRQ = 0

        ; Configurar timer: TOP = 10 (dispara cada 10 ciclos)
        li    10, r1
        store r1, r14, 6           ; TIMER_TOP (0x0406) = 10

        ; Habilitar interrupciones
        ei

        ; Bucle principal: no hace nada útil, solo espera IRQs
loop:   nop
        j     loop