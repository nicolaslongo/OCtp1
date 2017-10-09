#include <mips/regdef.h>
#include <sys/syscall.h>
.text
.abicalls
.globl esEspacio
.ent esEspacio

esEspacio:
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
	sw a0, 40($fp)		# salvo el caracter

# inicia el programa
	sub t4, a0, 45		# analizo si es el guion medio
	beq t4, zero, _noEs		
	sub t4, a0, 95		# analizo si es el guion bajo
	beq t4, zero, _noEs
	sub t4, a0, 48		# si es menor que 48 es un espacio
	bltz t4, _Es
	sub t4, a0, 122		# si es mayor que 122 es un espacio
	bgtz t4, _Es
	sub t4, a0, 57		# si es menor o igual que 57 seguro no es espacio [0,..,9]
	blez t4, _noEs
	sub t4, a0, 65		# si es menor a 65 seguro es espacio
	bltz t4, _Es
	sub t4, a0, 90		# si es menor o igual a 90 seguro no es espacio [A,...,Z]
	blez t4, _noEs
	sub t4, a0, 97		# si es menor que 97 seguro es espacio
	bltz t4, _Es
	b _noEs			# esta entre 97 y 122 [a,...,z]
_noEs:
	li v0, 0
	b _return
_Es:
	li v0, 1
	b _return

_return:
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end esEspacio
