#include <mips/regdef.h>
#include <sys/syscalls.h>
.text
.abicalls
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
	sw a1, 44($fp)		# salvo condición de lectura inicial (ex-pos inicial)
#	sw a2, 48($fp)		# salvo tamaño del buffer

_if:
	li t0, 1
	beq t0, a1, _lectura_inicial

#compruebo que quedan caracteres por leer
	subu t0, a0, POS_INICIAL_IB		# le resto la pos_inicial a la pos_actual
	subu t0, t0, TAM_IB		# al resultado, le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _rellenar_buffer

_lectura:
	lw v0, 40($fp)			# en v0 guardo el char (leído) que es lo que voy a devolver
	li t1, 8
	add v1, v0, t1			# en v1, la nueva posicion actual (la anterior, más el tamaño de un char) 
	b _return

_rellenar_buffer:
	li vo, sys_read
	li a0, FDESCRIPTOR_DE_LECTURA
	lw a1, POS_INICIAL_IB		# esto es más bien innecesario pero me aseguro que esté acá. acá está la pos_inicial del buffarini
	sw a1, 16($fp)		# me guardo la posición inicial en LTA por si tengo que hacer una relectura
	lw a2, TAM_IB		# y acá está el tamaño. lo mismo que arriba
	syscall

# Casos posibles:
#	1. El syscall puede leer todo, devuelve 0 y ibytes
#	2. El syscall puede leer parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a ibytes
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error y está en v0
#	4. El syscall devuelve 0 y 0 ----> eof
_comprobacion:	
	bltz a3, _error_en_syscall		
	beqz v0, _eof					
	subu t0, v0, IBYTES
	bgtz t0, _relectura				# si pasa ésta línea, entonces a3=0 y v0=ibytes

	lw t0, POS_INICIAL_IB
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
	li a0, FDESCRIPTOR_DE_LECTURA
	lw t1, 48($fp)
	subu t0, t1, v0		# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
	move a2, t0
	syscall
	b _comprobacion

_lectura_inicial:
	b _rellenar_buffer

_return:	# ya tengo en v0 la posición en memoria del char (leído) y en v1 mi nueva posición actual
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end