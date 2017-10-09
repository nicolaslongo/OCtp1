#include <mips/regdef.h>
#include <sys/syscall.h>
.text
.abicalls
.globl palindrome
.ent palindrome

palindrome:
	.frame $fp, 40, ra
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
	lw a0, 52($fp)		# preparo a0 para pasarselo a mymalloc
	jal mymalloc
	sw v0, 16($fp)		# salvo la posicion inicial del buffer en el stack frame	
	lw a0, 52($fp)		# preparo a0 para pasarselo a mymalloc, utilizamos el mismo tamanio que el buff in
	jal mymalloc		# en v0 tengo la posicion de memoria del buffer para palabras
	sw v0, 20($fp)		# lo salvo en el sf
	sw v0, POS_INICIAL_IB 	# lo guardo como variable global
									##########		
	lw a0, 16($fp)		# preparo los argumentos para getch, en v0 esta la posicion inicial del buffer
	lw a1, 16($fp)		# la posicion inicial y la actual es la misma en primera instancia
	lw a2, 44($fp)		# le paso el tamanio del buffer
	li a3, 1		# tiene que llenar el buffer		###VER###
	lw t0, 20($fp)		# inicializo un contador para moverme por el buffer de palabras
				# habria que ir de 8 en 8 porque cada char ocupa un byte
	lw t2, 20($fp)		# indica desde que lugar del buffer leer

lecturaArchivo:
	jal getch			# empiezo a leer
	beq v0, zero, finDeLectura	# si devuelve 0, es un EOF, sino sigue
	sw v0, AUX			# me guardo el char en t3
	lw t3, AUX
	sw v0, AUX			# preparo a0 para esEspacio
	lw a0, AUX
	jal esEspacio			# me fijo si el caracter es un espacio
					# en v0 esta si es un espacio = 1, sino = 0
	bne v0, zero, _analizarPalindromo	
_sigo:
	move t0, t3				# aca hay que meter el caracter leido en el buffer de palabras, creo que asi
	addu t0, t0, 8				# me muevo al proximo byte
	b lecturaArchivo			# sigo leyendo
	
_analizarPalindromo:
	move a0, t2		# pongo en a0 desde donde tengo que leer
	jal mystrlen
	sw v0, AUX		# en a0 tengo la posicion de comienzo del string
	subu a1, v0, 1	# guardo en a1 el len de la palabra -1 para palindromeString
	lw a1, AUX
	jal palindromeString
	sw t0, AUX
	lw t2, AUX		# actualizo t2
	addu t2, t2, 8
	b _sigo
	

finDeLectura:
	lw ra, 40(sp)
	lw $fp, 32(sp)
	lw gp, 36(sp)
	addu sp, sp, 48
	jr	ra

.end palindrome

.globl mystrlen
.ent mystrlen

mystrlen:
	.frame	$fp, 16, ra
	.set	noreorder
	.cpload t9
	.set	reorder

	# creo stack frame
	subu	sp, sp, 16	# 2 (SRA) + 2 (LTA)
	.cprestore 8		# sw gp, 8(sp)
	sw	$fp, 12(sp)
	move	$fp, sp

	# salvo 1er arg (siempre)
	sw	a0, 16($fp)			## redundante

	# for (i=0; s[i] != 0; i++)
	move	t0, zero	# i=0: t0, fp+0
	sw	t0, 0($fp)	# i: t0
_for_loop:
	# condicion de corte: s[i] != 0
	lw	a0, 16($fp)			## redundante
	lw	t0, 0($fp)			## redundante
	addu	t1, a0, t0	# s[i]: t1
	lb	t1, 0(t1)			## lb, NO lw!
	beq	t1, zero, _end_for
	
	lw	t0, 0($fp)	# i++		## redundante
	addu	t0, t0, 1
	sw	t0, 0($fp)			## redundante
	j	_for_loop

_end_for:
	lw	v0, 0($fp)			## podria ser un move v0, t0
	lw	gp, 8(sp)
	lw	$fp, 12(sp)
	addu	sp, sp, 16
	jr	ra

	.end	mystrlen
	.size	mystrlen,.-mystrlen

.data

AUX: .word 0
FDESCRIPTOR_DE_LECTURA: .word 0
FDESCRIPTOR_DE_ESCRITURA: .word 0
IBYTES: .word 0
OBYTES: .word 0
POS_INICIAL_IB: .word 0

