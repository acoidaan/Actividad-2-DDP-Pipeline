; ======================================================================
;  knapsack.asm  -  Problema de la mochila 0/1
;  Programacion dinamica (DP) iterativa con array 1D.
;
;  Caso de prueba:
;       n        = 3 items
;       S        = 6 (capacidad)
;       weights  = [1, 2, 3]
;       vals     = [10, 15, 40]
;
;  Resultado esperado:  memo[S] = 65 = 0x41
;       HEX1 = '4'  HEX0 = '1'
;       LEDG = 0100 0001
;
;  Notas sobre la implementacion:
;    - Sin flag de signo todavia (eso es Step 6), por lo que las
;      comparaciones de "menor que" se hacen con  (a-b) AND 0x8000
;      y se testea el bit de signo via Z tras el AND.
;    - r0 esta hardwired a 0; lo uso como base para acceder a la
;      memoria de datos baja (weights, vals, memo en 0x00..0x0C).
;    - r15 = 0x0400 base de perifericos para escribir HEX01/LEDG.
;    - DP 1D: recorro s desde S hacia abajo para no machacar
;      valores de la "fila i-1" que todavia necesito leer.
;
;  Mapa de registros:
;       r0  = 0 (hardwired)
;       r1  = 1               cte incremento
;       r2  = n  (=3)
;       r3  = S  (=6)
;       r4  = scratch / valor a escribir
;       r5  = puntero generico a memoria de datos
;       r6  = puntero / contador init / puntero memo[s-w]
;       r7  = i_minus_1 (contador externo)
;       r8  = s (contador interno)
;       r9  = w  = weights[i]
;       r10 = v  = vals[i]
;       r11 = diff = s - w  /  cur - candidate
;       r12 = 0x8000          mascara bit de signo
;       r13 = cur = memo[s]   /  bit de signo aislado
;       r14 = prev = memo[s-w]  ->  candidate = prev + v
;       r15 = 0x0400          base perifericos
;
;  Mapa de memoria de datos:
;       0x00..0x02   weights[0..2]
;       0x03..0x05   vals[0..2]
;       0x06..0x0C   memo[0..6]   (S+1 = 7 palabras)
; ======================================================================

; --- direcciones absolutas en memoria de datos ----------------------
; (sin espacios antes de ':' y en minusculas: el ensamblador hace
;  tolower al definir el simbolo, pero NO al referenciarlo, asi que
;  hay que escribirlos en minusculas en ambos sitios.)
addr_w0: equ 0
addr_w1: equ 1
addr_w2: equ 2
addr_v0: equ 3
addr_v1: equ 4
addr_v2: equ 5
addr_memo: equ 6

; --- offsets de E/S respecto a 0x0400 -------------------------------
ledg_off: equ 3      ; LEDG  = 0x0403
hex01_off: equ 4     ; HEX01 = 0x0404


; ====================================================================
; Inicializacion de constantes en registros
; ====================================================================
inicio:
    li 1,     r1                ; r1  = 1
    li 3,     r2                ; r2  = n = 3
    li 6,     r3                ; r3  = S = 6
    li 32768, r12               ; r12 = 0x8000 (mascara signo)
    li 1024,  r15               ; r15 = 0x0400 (base perifericos)

; ====================================================================
; Inicializar weights[0..2] = {1, 2, 3}
; ====================================================================
    li 1, r4
    store r4, r0, addr_w0
    li 2, r4
    store r4, r0, addr_w1
    li 3, r4
    store r4, r0, addr_w2

; ====================================================================
; Inicializar vals[0..2] = {10, 15, 40}
; ====================================================================
    li 10, r4
    store r4, r0, addr_v0
    li 15, r4
    store r4, r0, addr_v1
    li 40, r4
    store r4, r0, addr_v2

; ====================================================================
; Inicializar memo[0..S] a cero  (7 palabras desde 0x06)
; ====================================================================
    li addr_memo, r5            ; r5 = 6 (puntero)
    li 7,         r6            ; r6 = 7 (contador)
init_memo:
    store r0, r5, 0             ; mem[r5] = 0
    addi  r5, 1, r5             ; r5++
    subi  r6, 1, r6             ; r6--  (actualiza Z)
    jnz init_memo

; ====================================================================
; Bucle externo:  for (i_minus_1 = 0; i_minus_1 < n; i_minus_1++)
;     w = weights[i_minus_1]
;     v = vals[i_minus_1]
;     bucle interno sobre s
; ====================================================================
    li 0, r7                    ; r7 = i_minus_1 = 0

loop_i:
    sub r7, r2, r11             ; r11 = i - n   (actualiza Z)
    jz done                     ; si i == n, terminar

    ; cargar weights[i_minus_1] -> r9
    addi r7, addr_w0, r5        ; r5 = i + 0 = &weights[i]
    load r9, r5, 0

    ; cargar vals[i_minus_1] -> r10
    addi r7, addr_v0, r5        ; r5 = i + 3 = &vals[i]
    load r10, r5, 0

    ; --- bucle interno ---
    mov r3, r8                  ; r8 = s = S

loop_s:
    ; condicion s >= w ?
    ;   diff = s - w ;  si bit15(diff) = 1  ->  s < w  ->  salir
    sub r8, r9, r11             ; r11 = s - w
    and r11, r12, r13           ; r13 = r11 & 0x8000  (actualiza Z)
    jnz end_s                   ; si Z=0 -> bit signo -> s < w

    ; cur = memo[s]
    addi r8, addr_memo, r5      ; r5 = &memo[s]
    load r13, r5, 0             ; r13 = cur

    ; prev = memo[s - w]    (r11 todavia vale s - w)
    addi r11, addr_memo, r6     ; r6 = &memo[s-w]
    load r14, r6, 0             ; r14 = prev

    ; candidate = prev + v
    add r14, r10, r14           ; r14 = candidate

    ; if (candidate > cur)  memo[s] = candidate
    ;   equiv: si bit15(cur - candidate) = 1, entonces cur < candidate
    sub r13, r14, r11           ; r11 = cur - candidate
    and r11, r12, r13           ; r13 = bit signo  (actualiza Z)
    jz skip_update              ; Z=1 -> sin bit signo -> cur >= candidate
    store r14, r5, 0            ; memo[s] = candidate

skip_update:
    subi r8, 1, r8              ; s--
    j loop_s

end_s:
    addi r7, 1, r7              ; i_minus_1++
    j loop_i

; ====================================================================
; Resultado:  memo[S] -> HEX01 y LEDG
; ====================================================================
done:
    addi r3, addr_memo, r5      ; r5 = &memo[S]
    load r4, r5, 0              ; r4 = resultado

    store r4, r15, hex01_off    ; HEX01 = resultado  (HEX1='4', HEX0='1')
    store r4, r15, ledg_off     ; LEDG  = resultado (byte bajo)

forever:
    j forever