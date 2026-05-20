; =======================================================================
;  knapsack_full.asm
;  -----------------------------------------------------------------------
;  Demostracion integral que ejercita TODAS las ampliaciones de la CPU:
;
;    * Buses externos (dir, datos bidireccional, control)
;    * LOAD / STORE con desplazamiento
;    * Aritmetico-logicas con inmediato (ADDI, SUBI, ANDI)
;    * Subrutinas con CALL / RET (pila hw)
;    * Instrucciones de 32 bits / registros de 16 bits
;    * Memoria de datos (weights, vals, memo)
;    * Periferico SW   (lee la capacidad S del knapsack)
;    * Periferico KEY  (espera pulsacion en KEY[1] para arrancar)
;    * Periferico LEDG (indica estado: 0xAA esperando, 0x01 calculando, 0x80 ok)
;    * Periferico HEX01 (muestra el resultado memo[S])
;    * Periferico HEX23 (muestra el numero de ciclos consumidos)
;    * Periferico TIMER (mide el tiempo de ejecucion del DP)
;
;  Flujo:
;    1. tras reset, inicializa weights[]={1,2,3} y vals[]={10,15,40}
;    2. enciende LEDG=0xAA  "listo para empezar"
;    3. polling sobre KEY[1] hasta deteccion de pulsacion
;    4. LEDG=0x01  "calculando", lee S desde SW[3:0] (si SW=0, S=6)
;    5. arranca TIMER con TOP=0xFFFF (resetea counter y empieza a contar)
;    6. ejecuta knapsack 0/1 con DP iterativo (subrutina max via CALL/RET)
;    7. lee TIMER_COUNT, para el timer
;    8. muestra memo[S] en HEX01 y ciclos en HEX23
;    9. LEDG=0x80, espera a que se suelte KEY[1] y vuelve a 3.
;
;  Resultados esperados (weights=[1,2,3], vals=[10,15,40]):
;     S=4 ->  50  (0x32)
;     S=5 ->  55  (0x37)
;     S=6 ->  65  (0x41)
;     S=7 ->  65  (0x41)  (no cabe nada mas)
; =======================================================================

; --- offsets de los perifericos respecto a 0x0400 (base en r15) ---
sw_off:    equ 0     ; 0x0400  switches
key_off:   equ 1     ; 0x0401  push-buttons
ledg_off:  equ 3     ; 0x0403  LEDs verdes (8 bits)
hex01_off: equ 4     ; 0x0404  displays HEX0+HEX1 (16 bits)
hex23_off: equ 5     ; 0x0405  displays HEX2+HEX3
top_off:   equ 6     ; 0x0406  TIMER_TOP
cnt_off:   equ 7     ; 0x0407  TIMER_COUNT

; --- direcciones en memoria de datos ---
addr_w0:   equ 0
addr_w1:   equ 1
addr_w2:   equ 2
addr_v0:   equ 3
addr_v1:   equ 4
addr_v2:   equ 5
addr_memo: equ 6

; =======================================================================
;  PROGRAMA PRINCIPAL
; =======================================================================
inicio:
    ; --- constantes en registros que se conservan toda la vida ---
    li 1,     r1                 ; r1 = 1
    li 3,     r2                 ; r2 = n = 3
    li 32768, r12                ; r12 = 0x8000 (mascara bit signo)
    li 1024,  r15                ; r15 = 0x0400 (base perifericos)

    ; --- weights[0..2] = {1, 2, 3} ---
    li 1, r4
    store r4, r0, addr_w0
    li 2, r4
    store r4, r0, addr_w1
    li 3, r4
    store r4, r0, addr_w2

    ; --- vals[0..2] = {10, 15, 40} ---
    li 10, r4
    store r4, r0, addr_v0
    li 15, r4
    store r4, r0, addr_v1
    li 40, r4
    store r4, r0, addr_v2

; =======================================================================
;  Bucle de espera: senaliza "listo" en LEDG y hace polling de KEY[1]
;  (KEYs llegan ya invertidas por el HW: bit=1 cuando pulsada)
; =======================================================================
ready_loop:
    li 170, r4                   ; 0xAA = 170  "listo para empezar"
    store r4, r15, ledg_off
wait_press:
    load r4, r15, key_off
    li 2, r5                     ; mascara para KEY[1]
    and r4, r5, r6               ; r6 = KEY[1] aislada (Z=1 si no pulsada)
    jz wait_press

    ; --- LEDG = 0x01  "calculando" ---
    li 1, r4
    store r4, r15, ledg_off

    ; --- leer S desde SW[3:0] ---
    load r3, r15, sw_off
    li 15, r4                    ; mascara 0x0F
    and r3, r4, r3               ; r3 = S, Z=1 si S=0
    jnz s_valido
    li 6, r3                     ; S por defecto si SW=0
s_valido:

    ; --- arrancar timer: TOP=0xFFFF resetea counter y arranca ---
    li 65535, r4                 ; 0xFFFF
    store r4, r15, top_off

    ; --- inicializar memo[0..S] = 0   (S+1 palabras desde 0x06) ---
    li addr_memo, r5
    addi r3, 1, r6               ; r6 = S+1 (contador)
init_memo:
    store r0, r5, 0
    addi r5, 1, r5
    subi r6, 1, r6
    jnz init_memo

    ; =======================================================
    ; Bucle externo: for (i = 0; i < n; i++)
    ; =======================================================
    li 0, r7                     ; r7 = i_minus_1 = 0

loop_i:
    sub r7, r2, r11              ; i - n  (Z=1 si terminado)
    jz done

    addi r7, addr_w0, r5
    load r9, r5, 0               ; r9 = weights[i]

    addi r7, addr_v0, r5
    load r10, r5, 0              ; r10 = vals[i]

    mov r3, r8                   ; r8 = s = S

loop_s:
    ; condicion: s >= w ?
    sub r8, r9, r11              ; r11 = s - w
    and r11, r12, r13            ; r13 = bit signo (Z=1 si sin signo)
    jnz end_s                    ; si s<w, salir

    ; cur = memo[s]
    addi r8, addr_memo, r5
    load r13, r5, 0              ; r13 = cur

    ; candidate = memo[s-w] + v
    addi r11, addr_memo, r6
    load r14, r6, 0
    add r14, r10, r14            ; r14 = candidate

    ; r14 = max(r13, r14)  (subrutina, ejercita CALL/RET y pila hw)
    call max_func

    ; guardar resultado (siempre, ya tiene el max ganador)
    store r14, r5, 0

    subi r8, 1, r8               ; s--
    j loop_s

end_s:
    addi r7, 1, r7               ; i++
    j loop_i

; =======================================================================
;  Final: lee timer, presenta resultados, vuelve a esperar
; =======================================================================
done:
    load r6, r15, cnt_off        ; r6 = ciclos transcurridos
    store r0, r15, top_off       ; TOP=0 detiene el timer

    addi r3, addr_memo, r5
    load r4, r5, 0               ; r4 = memo[S] = resultado

    store r4, r15, hex01_off     ; HEX01 = resultado
    store r6, r15, hex23_off     ; HEX23 = ciclos

    li 128, r4                   ; 0x80
    store r4, r15, ledg_off      ; LEDG = 0x80  "listo"

    ; --- esperar a que se suelte KEY[1] antes de aceptar otra pulsacion ---
wait_release:
    load r4, r15, key_off
    li 2, r5
    and r4, r5, r6
    jnz wait_release

    j ready_loop

; =======================================================================
;  SUBRUTINA: max(r13, r14) -> r14
;     IN:   r13 = a (cur)    r14 = b (candidate)
;     OUT:  r14 = max(a, b)
;     CLOBBERS: r11
; =======================================================================
max_func:
    sub r13, r14, r11            ; r11 = a - b
    and r11, r12, r11            ; r11 = bit signo
    jnz max_done                 ; a < b  ->  ya r14 = b
    add r13, r0, r14             ; a >= b ->  r14 = a
max_done:
    ret
