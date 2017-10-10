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
	sw v0, POS_INICIAL_IB 	# lo guardo como variable global	
	lw a0, 52($fp)		# preparo a0 para pasarselo a mymalloc, utilizamos el mismo tamanio que el buff in
	jal mymalloc		# en v0 tengo la posicion de memoria del buffer para palabras
	sw v0, 20($fp)		# lo salvo en el sf

										
	lw a0, 16($fp)		# preparo los argumentos para getch, paso la posicion inicial del buffer, ahi arranca
	li a1, 1		# tiene que llenar el buffer
	lw t0, 20($fp)		# inicializo un contador para moverme por el buffer de palabras
				# habria que ir de 8 en 8 porque cada char ocupa un byte
	lw t2, 20($fp)		# indica desde que lugar del buffer leer

lecturaArchivo:
	jal getch			# empiezo a leer
	beq v0, zero, finDeLectura	# si devuelve 0, es un EOF, sino sigue
	move t3, v0			# me guardo el char en t3
	move a0, v0			# preparo a0 para esEspacio
	jal esEspacio			# me fijo si el caracter es un espacio
					# en v0 esta si es un espacio = 1, sino = 0
	beq v0, 0, _analizarPalindromo	
_sigo:
	move t0, t3			# aca hay que meter el caracter leido en el buffer de palabras, creo que asi
	addu t0, t0, 1			# me muevo al proximo byte
	move a0, v1			# preparo los argumentos para getch, paso la posicion actual del buffer
	li a1, 0			# hay que leer ahora
	b lecturaArchivo			# sigo leyendo
	
_analizarPalindromo:
	lw a0, 20($fp)	# pongo en a0 desde donde tengo que leer, comienzo de la palabra
	jal mystrlen
	subu a1, v0, 1		# guardo en a0 el len de la palabra -1 para palindromeString

	## write de prueba
	li v0, SYS_write
	li a0, 1 #salida
	syscall

	lw a0, 20($fp)
	jal palindromeString
	move t2, t0		# actualizo t2
	addu t2, t2, 1
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
########sw a2, 48($fp)		# salvo tamaño del buffer

_if:
	li t0, 1
	beq t0, a1, _lectura_inicial

#compruebo que quedan caracteres por leer
	la t2, POS_INICIAL_IB
	lw t1, 0(t2)
	subu t0, a0, t1		# le resto la pos_inicial a la pos_actual
	lw t1, IBYTES
	subu t0, t0, t1		# al resultado, le resto el tamaño. Si son iguales, tendré que pasar al syscall
	beq t0, zero, _rellenar_buffer

_lectura:
	#print de prueba
	#li v0, SYS_write
	#li a0, 1 #salida
	#lw a1, 40($fp) # guardo string
	#syscall

	lb v0, 40($fp)			# en v0 guardo el char (leído) que es lo que voy a devolver
	li t1, 1
	add v1, v0, t1			# en v1, la nueva posicion actual (la anterior, más el tamaño de un char) 
	b _return

_rellenar_buffer:
	li v0, SYS_read
	la t0, FDESCRIPTOR_DE_LECTURA
	lw a0, 0(t0)
	la t0, POS_INICIAL_IB
	lw a1, 0(t0)			
	sw a1, 16($fp)		# me guardo la posición inicial en LTA por si tengo que hacer una relectura
	lw a2, IBYTES		# y acá está el tamaño. lo mismo que arriba
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

.end getch

.data

AUX: .word 0
FDESCRIPTOR_DE_LECTURA: .word 0
FDESCRIPTOR_DE_ESCRITURA: .word 0
IBYTES: .word 0
OBYTES: .word 0
POS_INICIAL_IB: .word 0

