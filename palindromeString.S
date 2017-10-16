#include <mips/regdef.h>
#include <sys/syscall.h>
.text
.abicalls
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
# si es palindromo lo muestro con sys-write
_palindrome_true:
	li v0, SYS_write
	li a0, 1 #salida
	lw a1, 40($fp) # guardo string
	lw a2, 44($fp) # guardo la longitud menos uno
	addu a2, a2, 1	# le sumo uno
	syscall
# si no es palindromo simplemente termino
_palindrome_false:
	lw ra, 32(sp)
	lw $fp, 24(sp)
	lw gp, 28(sp)
	addu sp, sp, 40
	jr	ra

.end palindromeString
