#include <mips/regdef.h>
#include <sys/syscall.h>
.text
.abicalls
.globl putch
.ent putch

putch:
	.frame $fp, 40, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 40 	# pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 20
	sw $fp, 24(sp)		# salvo fp en 16
	sw ra, 32(sp)		# salvo ra en 24
	move $fp, sp		# a partir de acá trabajo con fp

# me guardo los parámetros que no guardo la caller (por convención de ABI)
	sw a0, 40($fp)		# salvo posicion actual del buffer
	sw a1, 44($fp)		# salvo el char a escribir (ex a3)
#	sw a1, 44($fp)		# salvo posicion inicial del buffer 
#	sw a2, 48($fp)		# salvo tamaño del buffer

# compruebo que quede espacio en el buffer de salida
	subu t0, a0, a1		# le resto la pos_inicial a la pos_actual
	subu t0, t0, a2		# al resultado le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _vaciar_buffer 

_escritura:
	lw a0, 44($fp)			# cargo el char a escribir en a0
	lw t2, 40($fp)			# cargo en t2 la pos_actual del buffer
	sb t2, (a0)				# guardo el char en la pos_actual del buffer
	li t1, 8
	add t2, t2, t1
	sw t2, 40($fp)
	move v0, t2
	b _return

_vaciar_buffer:
	li v0, SYS_write
	li a0, FDESCRIPTOR_DE_ESCRITURA
	lw a1, POS_INICIAL_OB		# acá guardo la posición inicial del buffer
	sw a1, 16($fp)				# me guardo la posición inicial en LTA por si tengo que hacer una reescritura
	lw a2, TAM_OB				# acá guardo el tamaño del buffer
	syscall

# Acá hay que verificar los 3 posibles casos:
#	1. El syscall puede escribir todo, devuelve 0 y obytes
#	2. El syscall puede escribir parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a obytesd
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error y está en v0

_comprobacion:
	bltz a3, _error_en_syscall		# si pasa ésta línea, no hubo error
	bltz v0, TAM_OB					# si pasa ésta línea, entonces a3=0 y v0=obytes
	lw t0, POS_INICIAL_OB
	sw t0, 40($fp)					# mi nueva pos_actual es la inicial
	b _escritura

_error_en_syscall: # devuelvo en v0 un -1 y en v1 el código de error (generado por el syscall)
	move v1, v0
	li v0, -1
	b _return

_reescritura:
	lw t0, 16($fp)			# mi posición inicial estaba en LTA. la levanto
	addu t0, t0, v0			# mi nueva posición inicial, será la anterior + los caracteres escritos
	sw t0, 26($fp)			# me guardo mi nueva posición inicial temporal en LTA
	move a1, t0
	li a0, FDESCRIPTOR_DE_ESCRITURA
	lw t1, 48($fp)			# cargo en t1 el tamaño del buffer
	subu a2, t1, v0			# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
	syscall
	b _comprobacion

_return:		# ya tengo en v0 la pos_actual nueva
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr ra

.end putch


