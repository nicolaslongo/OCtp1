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

	lw a0, IBYTES					# utilizamos tamanio que el buff in
	jal mymalloc					# en v0 tengo la posicion de memoria del buffer para palabras
	sw v0, 20($fp)					# pos_actual del buffwords
	sw v0, POS_INICIAL_BUFF_PAL

	lw a0, POS_INICIAL_IB			# preparo los argumentos para getch, paso la posicion actual del buffin (que resulta ser la inicial)
	li a1, 1						# tiene que llenar el buffer
lecturaArchivo:
	jal getch						# empiezo a leer
#	lw t0, 0(v0)
	beqz v0, finDeLectura			# si el char es 0, EOF. acá estamos evaluando si el puntero es 0. esto no debería cumplirse nunca
	sw v1, 16($fp)					# me guardo la posicion actual del buff in
	sw v0, 24($fp)					# me guardo el puntero al primer caracter
	
	move a0, v0						# guardo el último char leído
	lb a0, 0(a0)
	jal esEspacio					# me fijo si el caracter es un espacio
									# en v0 esta si es un espacio = 1, sino = 0
	beq v0, 0, _definirLargoDePalabra	

# si llegué acá es un espacio. ¿Para qué meteríamos el caracter en el buffer de palabras?
# sólo hay que aumentar el puntero a pos_in del buffin y perder en el camino esos caracteres
# si en definitiva no los queremos imprimir

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
#	beq v0, zero, _analizarPalindromoFinal ESTO HACÍA QUILOMBO
#	move t3, v0								# me guardo el caracter en t3
#	lb t3, 0(t3)
	lb a0, 0(v0)							# preparo a0 para esEspacio
#	beq a0, zero, finDeLectura				# si el char leído es un 0, EOF.
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
	lw a0, POS_INICIAL_BUFF_PAL
	move a1, t7
	jal palindromeString
	#lw t1, POS_INICIAL_BUFF_PAL
	move t7, zero							# pongo en cero mi registro t7 de nuevo

	lw a0, 16($fp)							# me preparo para seguir leyendo
	li a1, 0
	b lecturaArchivo
	
_analizarPalindromoFinal:
	beqz t7, finDeLectura					# ésta línea casi seguro es inútil
	lw a0, POS_INICIAL_BUFF_PAL
	#subu a1, t7, 1
	move a1, t7
	jal palindromeString

finDeLectura:
	lw ra, 40(sp)
	lw $fp, 32(sp)
	lw gp, 36(sp)
	addu sp, sp, 48
	jr	ra

.end palindrome

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
	lw a2, IBYTES			# y acá está el tamaño. lo mismo que arriba
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

AUX: .word 0
FDESCRIPTOR_DE_LECTURA: .word 0
FDESCRIPTOR_DE_ESCRITURA: .word 0
IBYTES: .word 0
OBYTES: .word 0
POS_INICIAL_IB: .word 0
POS_INICIAL_BUFF_PAL: .word 0
