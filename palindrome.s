#include <mips/regdef.h>
#include <sys/syscalls.h>
.text
.abicalls
.globl palindrome
.ent palindrome

palindrome:
	.frame $fp, 40, ra
	.set noreorder
	.cpload t9
	.set reorder

	subu sp, sp, 40 	# pido espacio para mi Stack Frame
	.cprestore 28		# salvo gp en 28
	sw $fp, 24(sp)		# salvo fp en 24
	sw ra, 32(sp)		# salvo ra en 32
	move $fp, sp		# a partir de acá trabajo con fp
	
# me guardo los parámetros tp1.c (por convención de ABI)
	sw a0, 40($fp)		# salvo el file descriptor del input file
	sw a1, 44($fp)		# salvo el tamanio del buffer de entrada
	sw a2, 48($fp)		# salvo el file descriptor del output file
	sw a3, 52($fp)		# salvo el tamanio del buffer de salida

# reservo memoria para el buffer de entrada
	lw a0, 44($fp)		# preparo a0 para pasarselo a mymalloc
	mymalloc
	# GETCH 
	
