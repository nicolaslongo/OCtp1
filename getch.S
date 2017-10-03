#include <mips/regdef.h>
#include <sys/syscalls.h>
.text
.abicalls
.globl getch
.ent getch

getch:
	.frame $fp, 32, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 32 	#pido espacio para mi Stack Frame
	.cprestore 20		# salvo gp en 20
	sw $fp, 16(sp)		# salvo fp en 16
	sw ra, 24(sp)		# salvo ra en 24
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros que no guardo la caller (por convención de ABI)
	sw a0, 32($fp)		# salvo posicion actual del buffer
	sw a1, 36($fp)		# salvo posicion inicial del buffer 
	sw a2, 40($fp)		# salvo tamaño del buffer

#compruebo que quedan caracteres por leer
#ÉSTAS RESTAS PUEDEN ESTAR AL REVÉS. OJO (la documentación no aclara)
	sub t0, a0, a1		# le resto la pos_inicial a la pos_actual
	sub t0, t0, a2		# al resultado, le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _pedir_mas_buffer

	li t1, 8
	lw v0, a0, t1		# mi nueva posicion actual (la anterior, más el tamaño de un char)
	b _return

_pedir_mas_buffer:
	li vo, sys_read
	li a0, FDESCRIPTOR_DE_LECTURA
	lw a1, 36($fp)		# esto es más bien innecesario pero me aseguro que esté acá. acá está la pos_inicial del buffarini
	lw a2, 40($fp)		# y acá está el tamaño. lo mismo que arriba
	syscall

# Acá hay que verificar los 3 posibles casos:
#	1. El syscall puede leer todo, devuelve 0 y 0
#	2. El syscall puede leer parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a tamaño del buffer
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error?
#Verifico el contenido de a3     beq a3, zero, _return_nuevo_buffer
_comprobacion:	
	bltz a3, _error_en_syscall		#si pasa ésta línea, no hubo error
	bgtz v0, _relectura				#si pasa ésta línea, entonces a3=0 y v0=0
	lw v0, 36($fp)					#mi nueva posición inicial es el comienzo del buffer
	b _return

_relectura		# acá voy a tener que poder traerme la anterior pos_actual (que en teoría será pos_inicial para la primera relectura, pero para la segunda puede cambiar)

	b _comprobacion

_return:	# ya tengo en v0 mi nueva pos_actual
	lw ra, 24(sp)
	lw $fp, 16(sp)
	lw gp, 20(sp)
	addu sp, sp, 32
	jr	ra

.end


	


