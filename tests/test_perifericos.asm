; Test de periféricos con memoria mapeada
; Mapa:
;   0x0000-0x03FF  Memoria datos
;   0x0400         Switches (lectura)     = base + 0
;   0x0401         Keys (lectura)         = base + 1
;   0x0402         LEDR (escritura)       = base + 2
;   0x0403         LEDG (escritura)       = base + 3
;   0x0404         HEX0+HEX1 (escritura)  = base + 4
;   0x0405         HEX2+HEX3 (escritura)  = base + 5

; r15 = base de periféricos (se reserva para esto)
        li    0x0400, r15

; --- Leer switches y copiar a LEDR ---
        load  r1, r15, 0          ; R1 = SW (dir 0x0400)
        store r1, r15, 2          ; LEDR = R1 (dir 0x0402)

; --- HEX0+HEX1: mostrar 0xAB (A en HEX1, B en HEX0) ---
        li    0x00AB, r2
        store r2, r15, 4          ; dir 0x0404

; --- HEX2+HEX3: mostrar 0xCD (C en HEX3, D en HEX2) ---
        li    0x00CD, r3
        store r3, r15, 5          ; dir 0x0405

; --- LEDG: encender alternados ---
        li    0x55, r4             ; 01010101
        store r4, r15, 3          ; dir 0x0403

; --- Memoria de datos: guardar y recuperar ---
        li    100, r5              ; base datos = 100
        li    0x1234, r6
        store r6, r5, 0           ; MEM[100] = 0x1234
        load  r7, r5, 0           ; R7 = MEM[100]

; --- Leer keys ---
        load  r8, r15, 1          ; R8 = keys (dir 0x0401)

bucle:  j     bucle