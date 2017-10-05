#include <mips/regdef.h>
#include <sys/syscalls.h>
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
	sw a1, 44($fp)		# salvo posicion inicial del buffer 
	sw a2, 48($fp)		# salvo tamaño del buffer
	sw a3, 52($fp)		# salvo la posición de memoria del char a escribir

# compruebo que quede espacio en el buffer de salida

	sub t0, a0, a1		# le resto la pos_inicial a la pos_actual
	sub t0, t0, a2		# al resultado le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _vaciar_buffer 

_lectura:
	lw t0, a3			# en t0 tengo el caracter a escribir?
	sw t0, a0			# en a0 guardo el caracter (esto es: escribo en a0 el caracter)
	li t1, 8
	sw t2, 40($fp)
	add t2, t2, t1
	lw v0, t2
	b _return

_vaciar_buffer:
	li v0, sys_write
	li a0, FDESCRIPTOR_DE_ESCRITURA
	lw a1, 44($fp)		# acá guardo la posición inicial del buffer
	sw a1, 16($fp)		# me guardo la posición inicial en LTA por si tengo que hacer una relectura
	lw a2, 48($fp)		# acá guardo el tamaño del buffer
	syscall

# Acá hay que verificar los 3 posibles casos:
#	1. El syscall puede escribir todo, devuelve 0 y 0
#	2. El syscall puede escribir parcialmente. Devuelve 0 (porque no hubo error) y un número positivo menor a tamaño del buffer
#	3. El syscall devuelve un número negativo (hubo error). Hay código de error y está en v0
# Verifico el contenido de a3 
_comprobacion:
	bltz a3, _error_en_syscall		# si pasa ésta línea, no hubo error
	bgtz v0, _reescritura			# si pasa ésta línea, entonces a3=0 y v0=0
	# ahora bien. hago la lectura propiamente dicha
	# para cuando pase de acá, la pos_actual deberá ser la pos_inicial
	lw t0, 44($fp)
	sw t0, 40($fp)
	b _lectura

_error_en_syscall

_reescritura:
	lw t0, 16($fp)			# mi posición inicial estaba en LTA. la levanto
	add t0, t0, v0			# mi nueva posición inicial, será la anterior + los caracteres escritos
	sw t0, 26($fp)			# me guardo mi nueva posición inicial temporal en LTA
	move a1, t0
	li a0, FDESCRIPTOR_DE_ESCRITURA
	lw t1, 48($fp)			# cargo en t1 el tamaño del buffer
	sub a2, t1, v0			# mi nuevo tamaño será el tamaño anterior - los caracteres leídos
	syscall
	b _comprobacion

_return:		# ya tengo en v0 la pos_actual nueva
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr ra

.end


