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
	move a0, a1					# preparo a0 para pasarselo a mymalloc
	jal mymalloc
	sw v0, 16($fp)					# salvo la posicion inicial del buffer en el stack frame
	sw v0, POS_INICIAL_IB 			# lo guardo como variable global

# reservo memoria para el buffer de palabras
	move a0, a1					# utilizamos tamanio que el buff in
	jal mymalloc					# en v0 tengo la posicion de memoria del buffer para palabras
	sw v0, 20($fp)					# pos_actual del buffwords
	sw v0, POS_INICIAL_BUFF_PAL

# reservo memoria para el buffer de salida
	move a0, a3
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
	sw v1, 16($fp)							# actualizo pos_actual del buffin
	lb a0, 0(v0)							# preparo a0 para esEspacio
	move t3, a0
	jal esEspacio							# me fijo si el caracter es un espacio
	beq v0, 1, _analizarPalindromo 			# si el caracter es un espacio no escribo ni sumo nada
	addu t7, t7, 1							# escribí caracter más
	lw t1, 20($fp)							# me traigo la pos actual del buff pal
	sb t3, 0(t1)							# guardo el dato
	addu t1, t1, 1							# adelanto el indice de buff pal
	sw t1, 20($fp)							# guardo la pos actual de buff pal
	b _loopEsPalabra

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
	#lw a0, POS_INICIAL_BUFF_PAL
	#jal myfree
	#lw a0, POS_INICIAL_OB
	#jal myfree

	lw ra, 40(sp)
	lw $fp, 32(sp)
	lw gp, 36(sp)
	addu sp, sp, 48
	jr	ra

.end palindrome

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

	beq a3, 2, _return_pal	# SI LE PASO UN 2 SIGNIFICA QUE NO TENGO QUE ANALIZAR
							# NINGUN PALINDROMO, SOLO INDICAR QUE ESCRIBA LO QUE 
							# TIENE EN EL BUFFER A PUTCH

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
	subu t0, a0, t1				# le resto la pos_inicial a la pos_actual
	sw t0, 20($fp)				# lo guardo en el stack frame
	beq a2, 2, _vaciar_buffer_final	# si a2 es 2 (con 1 rompia, nose porque) significa que es una ultima escritura
	lw t1, OBYTES
	subu t0, t0, t1				# al resultado le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, 0, _vaciar_buffer 

_escritura_putch:
	lw t0, 44($fp)			# cargo el puntero al char a escribir en t0
	lb t3, 0(t0)
	lw t2, 40($fp)			# cargo en t2 la pos_actual del buffer de salida
	sb t3, 0(t2)			# guardo el char en la pos_actual del buffer de salida
	addu t2, t2, 1			# en v1, la nueva posicion actual (la anterior, más el tamaño de un char)
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

	#PRINT PARA ASEGURARME QUE ENTRO EN LA ULTIMA ESCRITURA
#	li v0, SYS_write
#	li a0, 1 #salida
#	la a1, ENTRE # guardo string
#	li a2, 6
#	syscall
	#################################################


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
# esto funciona sólo si en v0 tengo los bytes que sí puedo escribir

_reescritura:
	sw t1, 16($fp)			# mi nueva posición inicial estaba en t1. la guardo en LTA
	move a1, t1 			# ya tengo en a1 el puntero al string
	la t3, FDESCRIPTOR_DE_ESCRITURA
	lw a0, 0(t3)			# ya tengo en a0 el FD
# mi nuevo tamaño será el tamaño anterior - los caracteres escritos
	lw t2, 20($fp)			# esto en realidad puede ir variando la segunda o tercera vez que entre
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
	lb t3, 0(v0)			# para gdb
	addu v1, v0, 1			# en v1, la nueva posicion actual (la anterior, más el tamaño de un char)

	b _return

_rellenar_buffer:
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
	subu t0, t1, v0					# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
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
ENTRE: .asciiz "ENTRE\n"
