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

	subu sp, sp, 40 	#pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 20
	sw $fp, 24(sp)		# salvo fp en 16
	sw ra, 32(sp)		# salvo ra en 24
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros que no guardo la caller (por convención de ABI)
	sw a0, 40($fp)		# salvo posicion actual del buffer
	sw a1, 44($fp)		# salvo posicion inicial del buffer 
	sw a2, 48($fp)		# salvo tamaño del buffer

#compruebo que quedan caracteres por leer
#ÉSTAS RESTAS PUEDEN ESTAR AL REVÉS. OJO (la documentación no aclara)
	sub t0, a0, a1		# le resto la pos_inicial a la pos_actual
	sub t0, t0, a2		# al resultado, le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _pedir_mas_buffer

	sw v0, a0			# en v0 guardo la posición en memoria del char leído
	li t1, 8
	lw v1, a0, t1		# en v1, la nueva posicion actual (la anterior, más el tamaño de un char) - esto se puede evitar haciendo que palindrome le sume uno a su posición actual
	b _return

_pedir_mas_buffer:
	li vo, sys_read
	li a0, FDESCRIPTOR_DE_LECTURA
	lw a1, 44($fp)		# esto es más bien innecesario pero me aseguro que esté acá. acá está la pos_inicial del buffarini
	sw a1, 16($fp)		# me guardo la posición inicial en LTA por si tengo que hacer una relectura
	lw a2, 48($fp)		# y acá está el tamaño. lo mismo que arriba
	syscall

# Acá hay que verificar los 3 posibles casos:
#	1. El syscall puede leer todo, devuelve 0 y 0
#	2. El syscall puede leer parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a tamaño del buffer
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error?
#Verifico el contenido de a3     beq a3, zero, _return_nuevo_buffer
_comprobacion:	
	bltz a3, _error_en_syscall		#si pasa ésta línea, no hubo error
	bgtz v0, _relectura				#si pasa ésta línea, entonces a3=0 y v0=0
	lw t0, 44($fp)					#mi nueva posición inicial es el comienzo del buffer
	move v0, t0
	add t0, t0, 8
	move v1, t0
	b _return

_relectura	
	lw t0, 16($fp)			# mi posición inicial estaba en LTA. la levanto
	add t0, t0, v0			# mi nueva posición inicial, será la anterior + los caracteres leídos
	sw t0, 16($fp)			# me guardo la nueva posición inicial temporal en LTA
	move a1, t0
	li a0, FDESCRIPTOR_DE_LECTURA
	lw t1, 48($fp)
	sub t0, t1, v0		# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
	move a2, t0
	syscall
	b _comprobacion

_return:	# ya tengo en v0 la posición en memoria del char a leer y en v1 mi nueva posición actual
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end