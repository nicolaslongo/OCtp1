#include <mips/regdef.h>
#include <sys/syscall.h>
.text
.abicalls
.globl palindrome
.ent palindrome

palindrome:
	.frame $fp, 48, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 48 	# pido espacio para mi Stack Frame
	.cprestore 36		# salvo gp en 36
	sw $fp, 32(sp)		# salvo fp en 32
	sw ra, 40(sp)		# salvo ra en 40
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros tp1.c (por convención de ABI)
	sw a0, 48($fp)		# salvo el file descriptor del input file
	sw a1, 52($fp)		# salvo el tamanio del buffer de entrada
	sw a2, 56($fp)		# salvo el file descriptor del output file
	sw a3, 60($fp)		# salvo el tamanio del buffer de salida

# me guardo los parámetros como variables globales
	sw a0, FDESCRIPTOR_DE_LECTURA
	sw a1, IBYTES
	sw a2, FDESCRIPTOR_DE_ESCRITURA
	sw a3, OBYTES

# reservo memoria para el buffer de entrada
	lw a0, IBYTES					# preparo a0 para pasarselo a mymalloc
	jal mymalloc
	sw v0, 16($fp)					# salvo la posicion inicial del buffer en el stack frame
	sw v0, POS_INICIAL_IB 			# lo guardo como variable global

# reservo memoria para el buffer de palabras
	lw a0, TAM_BUFF_PAL				# arrancamos con tamanio de buffer de 200, si viene una palabra
									# mas grande habria que "redimensionar"
	jal mymalloc					# en v0 tengo la posicion de memoria del buffer para palabras
	sw v0, 20($fp)					# pos_actual del buffwords
	sw v0, POS_INICIAL_BUFF_PAL

# reservo memoria para el buffer de salida
	lw a0, OBYTES
	jal mymalloc
	sw v0, 28($fp)
	sw v0, POS_INICIAL_OB

	lw a0, POS_INICIAL_IB			# preparo los argumentos para getch, paso la posicion actual del buffin (que resulta ser la inicial)
	li a1, 1						# tiene que llenar el buffer
lecturaArchivo:
	jal getch						# empiezo a leer
	beqz v0, _analizarPalindromoFinal			# si el char es 0, EOF. 
	sw v1, 16($fp)					# me guardo la posicion actual del buff in
	sw v0, 24($fp)					# me guardo el puntero al primer caracter
	
	move a0, v0						# guardo el último char leído
	lb a0, 0(a0)
	jal esEspacio					# me fijo si el caracter es un espacio
									# en v0 esta si es un espacio = 1, sino = 0
	beq v0, 0, _definirLargoDePalabra	

_noEsPalabra:
	lw a0, 16($fp)							# si no es palabra, cargo la posicion actual del buff in y vuelvo
	li a1, 0
	b lecturaArchivo						# sigo leyendo

_definirLargoDePalabra:
	lw t0, 24($fp)							# cargo el puntero en t0
	lb t0, 0(t0)							# cargo el dato en t0
	lw t1, POS_INICIAL_BUFF_PAL				# cargo la posicion del primer caracter
	sb t0, 0(t1)							# guardo el dato
	addu t1, t1, 1							# adelanto el indice en buff pal
	sw t1, 20($fp)							# salvo el indice, pos actual del buff pal
	li t7, 0								# inicializo t7 en 0 porque ya detecté el primer caracter

_loopEsPalabra:
	lw a0, 16($fp)							# preparo los argumentos para getch, paso la posicion actual del buffin
	li a1, 0								# no es la primera lectura
	jal getch								# guardarse v1 en el stack
	beqz v0, _analizarPalindromoFinal
	sw v1, 16($fp)							# actualizo pos_actual del buffin
	lb a0, 0(v0)							# preparo a0 para esEspacio
	move t3, a0
	sw v0, ULTIMO_CHAR_REDIM
	jal esEspacio							# me fijo si el caracter es un espacio
	beq v0, 1, _analizarPalindromo 			# si el caracter es un espacio no escribo ni sumo nada
	b _analizar_redimension					# me fijo si hay que redimensionar, sino sigo
_sigo:	
	addu t7, t7, 1							# escribí caracter más
	lw t1, 20($fp)							# me traigo la pos actual del buff pal
	sb t3, 0(t1)							# guardo el dato
	addu t1, t1, 1							# adelanto el indice de buff pal
	sw t1, 20($fp)							# guardo la pos actual de buff pal
	b _loopEsPalabra

_analizar_redimension:
	lw t0, POS_INICIAL_BUFF_PAL				# cargo la posicion inicial del buff pal
	lw t1, 20($fp)							# cargo la posicion actual del buff pal
	subu t0, t1, t0							# resto
	lw t1, TAM_BUFF_PAL						
	subu t0, t1, t0
	beq t0, zero, _redimension 				# si esta lleno redimensiono
	b _sigo									# sino vuelvo a donde me llamaron

_redimension:
	jal redimensionar
	sw v0, 20($fp)							# actualizo la pos actual del buff pal
	lw t3, ULTIMO_CHAR_REDIM
	lb t3, 0(t3)
	b _sigo

# si salgo de acá, entonces ya tengo la palabra entera en el buffwords
_analizarPalindromo:

	lw a0, POS_INICIAL_BUFF_PAL				# preparo parametros para palindrome
	move a1, t7								# posicion en el buffer de palabras, longitud -1
	lw a2, 28($fp)							# posicion en el buffer out
	jal palindromeString
	sw v0, 28($fp)							# guardo la pos actual del buff out
	move t7, zero							# pongo en cero mi registro t7 de nuevo
	lw a0, 16($fp)							# me preparo para seguir leyendo
	li a1, 0
	b lecturaArchivo

_analizarPalindromoFinal:

	li a3, 2								# esto es para indicarle a putch que es la ultima escritura
	lw a2, 28($fp)
	jal palindromeString

finDeLectura:

	lw a0, POS_INICIAL_IB					# preparo los argumentos para
	jal myfree								# liberar la memoria pedida
	lw a0, POS_INICIAL_BUFF_PAL
	jal myfree
	lw a0, POS_INICIAL_OB
	jal myfree

	lw ra, 40(sp)
	lw $fp, 32(sp)
	lw gp, 36(sp)
	addu sp, sp, 48
	jr	ra

.end palindrome

.globl redimensionar
.ent redimensionar

redimensionar:

	.frame $fp, 48, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 48 	# pido espacio para mi Stack Frame
	.cprestore 36		# salvo gp en 36
	sw $fp, 32(sp)		# salvo fp en 32
	sw ra, 40(sp)		# salvo ra en 40
	move $fp, sp		# a partir de acá trabajo con fp
	

	lw t0, TAM_BUFF_PAL		# multiplico el tamanio actual x 2
	addu t0, t0, t0			# para el nuevo malloc
	sw t0, 20($fp)			# me guardo el nuevo tamanio 
	move a0, t0				# preparo a0
	jal mymalloc
	sw v0, 16($fp)			# en v0 tengo la posicion inicial del nuevo buffer
	li t0, 0				# inicializo un contador
	

_loop_llenar_buffer:
	lw t1 , POS_INICIAL_BUFF_PAL
	addu t1, t1, t0					# calculo la posicion en el buff pal viejo
	lb t2, 0(t1)					# cargo el char
	lw t6, 16($fp)
	addu t6, t6, t0					# calculo la pos actual en el nuevo buff
	sb t2, 0(t6)					# meto el char en el nuevo buff
	addu t0, t0, 1					# aumento contador
	lw t1, TAM_BUFF_PAL				# cargo el tamanio del buffer
	subu t2, t1, t0 				# resto
	sw t0, 24($fp)
	bnez t2, _loop_llenar_buffer	# si no es 0 sigo loopeando

_return_redimensionar:

	lw a0, POS_INICIAL_BUFF_PAL		# libero el malloc anterior
	jal myfree

	lw t1, 16($fp)					# preparo la posicion a devolver
	lw t0, 24($fp)
	addu t1, t1, t0
	move v0, t1
	lw t0, 20($fp)					# actualizo variables globales
	sw t0, TAM_BUFF_PAL
	lw t0, 16($fp)
	sw t0, POS_INICIAL_BUFF_PAL

	lw ra, 40(sp)
	lw $fp, 32(sp)
	lw gp, 36(sp)
	addu sp, sp, 48
	jr	ra

.end redimensionar

.globl palindromeString
.ent palindromeString

palindromeString:
	.frame $fp, 40, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 40 	# pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 28
	sw $fp, 24(sp)		# salvo fp en 24
	sw ra, 32(sp)		# salvo ra en 32
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros (por convención de ABI)
	sw a0, 40($fp)		# salvo el string
	sw a1, 44($fp)		# longitud string menos uno
	sw a2, 48($fp)		# pos_actual del buff de salida
	sw a3, 52($fp)		# guardo el tipo de escritura a pasarle a putch

	sw a2, 20($fp)		# la guardo en el stack frame de palindromeString

# Si el programa recibe un 2, significa que no debe analizar ningún palindromo
# sino vaciar el buffer de palabras
	beq a3, 2, _return_pal	

# guardo en t0 el comienzo del string
	move t0, a0
# guardo en t1 el final del string
	addu t1, a0, a1
# guardo en t2 la mitad del string (le sumo uno porque trunca)
	div t2, a1, 2
	addu t2, t2, 1
# guardo en t3 las posiciones que revise (inicializo en 0)
	xor t3, t3, t3
# sigo revisando si no recorri la mitad del string
_palindrome_loop:
# si ya compare todo el string finalizo
	beq t2, t3, _palindrome_true
# cargo t0 y t1
	lb t4, 0(t0)
	lb t5, 0(t1)
# si los caracteres espejo no son iguales entonces no es palindromo
	bne t4, t5, _palindrome_false
# seteo t0 y t1 para comparar los siguientes caracteres	
	addu t0, t0, 1
	subu t1, t1, 1
# aumento contador
	addu t3, t3, 1
	b _palindrome_loop
# si es palindromo le paso caracter por caracter a putch
_palindrome_true:
	lw t0, 40($fp)		# en t0 tengo el string
	lw t1, 44($fp)		# en t1 tengo la longitud
	lw t2, 20($fp)		# en t2 tengo la pos_actual del buff de salida
	li t3, 0			# en t3 tengo el contador
	sw t3, 16($fp)		# guardo el contador a 16 de fp
	move a0, t2
	move a1, t0
	li a2, 0
_loop_putch:
	jal putch
	lw t3, 16($fp)		# cargo el contador en t3
	sw v0, 20($fp)		# me guardo la nueva pos_actual
	lw t1, 44($fp)		# en t1 tengo la longitud - 1
	subu t4, t1, t3
	beq t4, 0, _return_pal
	addu t3, t3, 1		# incremento el contador
	sw t3, 16($fp)		# lo vuelvo a guardar
	move a0, v0
	lw t0, 40($fp)		# en t0 tengo el string
	addu a1, t0, t3
	li a2, 0
	b _loop_putch
	
_return_pal:
	lw a0, 20($fp)			# cargo la posicion actual del buff out
	la a1, SALTO_DE_LINEA	# cargo el salto de linea como caracter a imprimir
	lw a2, 52($fp)			# indico que tipo de escritura es, final o normal
	jal putch 				# lo meto en buff out, para imprimir
	sw v0, 20($fp)			

# si no es palindromo simplemente termino
_palindrome_false:
	lw v0, 20($fp)			# devuelvo la nueva pos_actual del buff de salida
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end palindromeString

.globl putch
.ent putch

putch:
	.frame $fp, 40, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 40 	# pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 28
	sw $fp, 24(sp)		# salvo fp en 24
	sw ra, 32(sp)		# salvo ra en 32
	move $fp, sp		# a partir de acá trabajo con fp

# me guardo los parámetros que no guardo la caller (por convención de ABI)
	sw a0, 40($fp)		# salvo posicion actual del buffer
	sw a1, 44($fp)		# salvo el puntero al char a escribir
	sw a2, 48($fp)		# salvo el tipo de escritura

# compruebo que quede espacio en el buffer de salida
	la t2, POS_INICIAL_OB
	lw t1, 0(t2)
	subu t0, a0, t1						# le resto la pos_inicial a la pos_actual
	sw t0, 20($fp)						# lo guardo en el stack frame
	beq a2, 2, _vaciar_buffer_final		# si a2 es 2 significa que es una ultima escritura
	lw t1, OBYTES
	subu t0, t0, t1						# al resultado le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, 0, _vaciar_buffer 

_escritura_putch:
	lw t0, 44($fp)			# cargo el puntero al char a escribir en t0
	lb t3, 0(t0)
	lw t2, 40($fp)			# cargo en t2 la pos_actual del buffer de salida
	sb t3, 0(t2)			# guardo el char en la pos_actual del buffer de salida
	addu t2, t2, 1			# en t2, la nueva posicion actual (la anterior, más el tamaño de un char)
	sw t2, 40($fp)
	move v0, t2
	b _return_putch

_vaciar_buffer:
	li v0, SYS_write
	la t0, FDESCRIPTOR_DE_ESCRITURA
	lw a0, 0(t0)
	la t0, POS_INICIAL_OB
	lw a1, 0(t0)				# acá guardo la posición inicial del buffer
	lw a2, 20($fp)				# acá guardo el tamaño del buffer a imprimir
	syscall
	la t0, POS_INICIAL_OB		# la posicion actual vuelve a ser la inicial
	lw v0, 0(t0)
	sw v0, 40($fp)
	b _escritura_putch

_vaciar_buffer_final:
	li v0, SYS_write
	la t0, FDESCRIPTOR_DE_ESCRITURA
	lw a0, 0(t0)
	la t0, POS_INICIAL_OB
	lw a1, 0(t0)				# acá guardo la posición inicial del buffer
	sw a1, 16($fp)
	lw a2, 20($fp)				# acá guardo el tamaño del buffer a imprimir
	syscall

	_comprobacion_putch:	
	bltz a3, _error_en_syscall_putch
	addu t5, v0, a3		
	lw t2, 20($fp)				# tamaño del buffer que debía imprimir					
	subu t5, t2, t5
	beqz t5, _putch_exitoso
# si llegué hasta acá leyó menos que el tamaño que debía imprimir
	lw t1, 16($fp)				# pos_inicial de lectura
	addu t1, t1, v0				# le sumo a la posicion inicial lo que ya escribi

_reescritura:
	sw t1, 16($fp)			# mi nueva posición inicial estaba en t1. la guardo en LTA
	move a1, t1 			# ya tengo en a1 el puntero al string
	la t3, FDESCRIPTOR_DE_ESCRITURA
	lw a0, 0(t3)			# ya tengo en a0 el FD
# mi nuevo tamaño será el tamaño anterior - los caracteres escritos
	lw t2, 20($fp)	
	subu a2, t2, t5
	sw a2, 20($fp)			# me guardo el nuevo tamaño a leer para comprobar luego
	syscall
	b _comprobacion_putch

_error_en_syscall_putch: # devuelvo en v0 un -1 y en v1 el código de error (generado por el syscall)
	move v1, v0
	li v0, -1
	b _return_putch

_putch_exitoso:
	la t0, POS_INICIAL_OB
	lw v0, 0(t0)

_return_putch:			# ya tengo en v0 la pos_actual nueva
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr ra

.end putch

.globl getch
.ent getch

getch:
	.frame $fp, 40, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 40 	# pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 28
	sw $fp, 24(sp)		# salvo fp en 24
	sw ra, 32(sp)		# salvo ra en 32
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros que no guardo la caller (por convención de ABI)
	sw a0, 40($fp)		# salvo posicion actual del buffer
	sw a1, 44($fp)		# salvo condición de lectura inicial

_if:
	li t0, 1
	beq t0, a1, _lectura_inicial

#compruebo que quedan caracteres por leer
	la t2, POS_INICIAL_IB
	lw t1, 0(t2)
	subu t0, a0, t1		# le resto la pos_inicial a la pos_actual
	lw t1, IBYTES
	subu t0, t0, t1		# al resultado, le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, 0, _rellenar_buffer

_lectura:
	lw v0, 40($fp)			# en v0 guardo el char (leído) que es lo que voy a devolver
	lb t3, 0(v0)
	addu v1, v0, 1			# en v1, la nueva posicion actual (la anterior, más el tamaño de un char)
	b _return

_rellenar_buffer:

	lw a2, IBYTES
	subu a2, a2, 1
	la t0, POS_INICIAL_IB
	lw t0, 0(t0)

_inicializar:
	la t2, ESPACIO
	lb t2, 0(t2)
	sb t2, 0(t0)
	subu a2, a2, 1
	addu t0, t0, 1
	bgtz a2, _inicializar


	li v0, SYS_read
	la t0, FDESCRIPTOR_DE_LECTURA
	lw a0, 0(t0)
	la t0, POS_INICIAL_IB
	lw a1, 0(t0)			
	sw a1, 16($fp)			# me guardo la posición inicial en LTA por si tengo que hacer una relectura
	lw a2, IBYTES			# y acá está el tamaño
	syscall	

# Casos posibles:
#	1. El syscall puede leer todo, devuelve 0 y ibytes
#	2. El syscall puede leer parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a ibytes
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error y está en v0
#	4. El syscall devuelve 0 y 0 ----> eof
_comprobacion:	
	bltz a3, _error_en_syscall
	addu t5, v0, a3		
	beqz t5, _eof
	la t2, IBYTES
	lw t1, 0(t2)					
	subu t0, v0, t1

	la t2, POS_INICIAL_IB
	lw t1, 0(t2)
	subu t0, t0, t1

	bgtz t0, _relectura				# si pasa ésta línea, entonces a3=0 y v0=ibytes

	la t2, POS_INICIAL_IB
	lw t0, 0(t2)
	sw t0, 40($fp)					# mi pos_actual es pos_inicial
	b _lectura

_error_en_syscall: # devuelvo en v0 un -1 y en v1 el código de error (generado por el syscall)
	move v1, v0
	li v0, -1
	b _return

_eof: # devuelvo en v0 un 0 y en v1 un 0
	li v0, 0
	li v1, 0
	b _return

_relectura:	
	lw t0, 16($fp)			# mi posición inicial estaba en LTA. la levanto
	add t0, t0, v0			# mi nueva posición inicial, será la anterior + los caracteres leídos
	sw t0, 16($fp)			# me guardo la nueva posición inicial temporal en LTA
	move a1, t0
	la t3, FDESCRIPTOR_DE_LECTURA
	lw a0, 0(t3)
	lw t1, 48($fp)
	subu t0, t1, v0			# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
	move a2, t0
	syscall
	b _comprobacion

_lectura_inicial:
	b _rellenar_buffer

_return:
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end getch

.data

FDESCRIPTOR_DE_LECTURA: .word 0
FDESCRIPTOR_DE_ESCRITURA: .word 0
IBYTES: .word 0
OBYTES: .word 0
POS_INICIAL_IB: .word 0
POS_INICIAL_OB: .word 0
POS_INICIAL_BUFF_PAL: .word 0
SALTO_DE_LINEA: .asciiz "\n"
ESPACIO: .byte ' '
TAM_BUFF_PAL: .word 100
ULTIMO_CHAR_REDIM: .word
