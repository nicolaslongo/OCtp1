#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>
#include "palindrome.h"

int palindrome(int ifd, size_t ibytes, int ofd, size_t obytes);

int aperturaDeArchivos(char* inName, FILE** input_file, char* outName, FILE** output_file){
	if (inName == NULL){
		*input_file = stdin;
	}
	else{
		if ((*input_file = fopen(inName, "rt")) == NULL){
			if (fprintf(stderr,"No se pudo abrir el archivo el archivo de entrada: %s\n", strerror(errno)) < 0){
				fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
			}
			return -1;
		}
	}
	if (outName == NULL){
		*output_file = stdout;
	}
	else{
		if ((*output_file = fopen(outName, "wt")) == NULL){
			if (fprintf(stderr,"No se pudo abrir el archivo el archivo de salida: %s\n", strerror(errno)) < 0){
				fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
			}
			return -1;
		}
	}
	return 0;
}
		

char* seIngresoParametro_io(char* par, int len, char** argv){
	if (strcmp(par, "-i") == 0){
		int i;
		for (i = 1; i < len; i++){
			if (strcmp(argv[i], "-i") == 0){
				return argv[i+1];
			}
		}
	}
	else{
		int j;
		for (j = 1; j < len; j++){
			if (strcmp(argv[j], "-o") == 0){
				return argv[j+1];
			}
		}
	}
	return NULL;
}

size_t seIngresoParametro_buf(char* par, int len, char** argv){
	char* ptr;
	if (strcmp(par, "-I") == 0){
		int i;
		for (i = 1; i < len; i++){
			if (strcmp(argv[i], "-I") == 0){
				return (size_t) strtol(argv[i+1], &ptr, 10);
			}
		}
	}
	else{
		int j;
		for (j = 1; j < len; j++){
			if (strcmp(argv[j], "-O") == 0){
				return (size_t) strtol(argv[j+1], &ptr, 10);
			}
		}
	}
	return 1;
}

int verificarParametrosInvalidos(int len, char** argv){
	char* ptr;
	int i;
	for (i = 1; i < len; i+=2){ //SALTO DE PARAMETRO EN PARAMETRO, PREVIAMENTE EN EL MAIN VERIFIQUE
					//EL PODER REALIZAR ESTOS SALTOS.
		if (strcmp(argv[i], "-i") == 0 || strcmp(argv[i], "-o") == 0 ||
		    strcmp(argv[i], "-I") == 0 || strcmp(argv[i], "-O") == 0){
			//ANALIZO SI -I Y -O SON NUMEROS VALIDOS
			if (strcmp(argv[i], "-I") == 0 || strcmp(argv[i], "-O") == 0){
				if (strtol(argv[i+1], &ptr, 10) <= 0){
					return 1;
				}
			}
		}
		else{
			return 1;
		}
	}
	return 0;
}

int mostrarMensajeVersion()
{

  if (printf("%s\n", "Version 1.0") < 0){
	fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
	return -1;
	}
  return 0;
}

int mostrarMensajeAyuda()
{
  if (printf("%s\n", "Usage:\ntp0 -h\ntp0 -V\ntp0 [options]\nOptions:\n-V, --version	Print version and quit.\n-h, --help	Print this information.\n-i, --input	Location of the input file.\n-o, --output	Location of the output file.\n-I, --ibuf-bytes	Byte-count of the input buffer.\n-O, --obuf-bytes	Byte-count of the output buffer.\nExamples:\ntp0 -i ~/input -o ~/output -I ~/buf_in_size -O ~/buf_out_size") < 0){
	fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
	return -1;
	}
  return 0;
}

int mostrarMensajeErrorParametrosInvalidos()
{
  if (fprintf(stderr, "Los parámetros ingresados no son válidos.\n") < 0){
	fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
	}
  return -1;
}

int main(int argc, char** argv){

	char* input_fileName;
	char* output_fileName;
	size_t bufferIn, bufferOut;

  // No puede ser mayor que nueve porque sólo se pueden pasar 8 parametros al programa más el "nombre del programa" que se encuentra en el arc
  // No puede tener ni 4 ni 6 ni 8 párametros porque significaria que "-i" o "-o" o "-I" o "-O" no tienen el nombre del archivo especificado o el
  // tamanio de los buffers
  if (argc > 9 || argc == 4 || argc == 6 || argc == 8)
  {
    return mostrarMensajeErrorParametrosInvalidos();
  }

  // Si se recibió un solo parámetro
  if (argc == 2)
  {
    if (strcmp(argv[1], "-V") == 0)
    {
      return mostrarMensajeVersion();
    }
    else if (strcmp(argv[1], "-h") == 0)
    {
      return mostrarMensajeAyuda();
    }
    else
    {
      return mostrarMensajeErrorParametrosInvalidos();
    }
  }
  
  if (verificarParametrosInvalidos(argc, argv)){
	return mostrarMensajeErrorParametrosInvalidos();
  }
	//ESTO FUE UNA PRUEBA PARA VER SI ANDABA Todo.
  input_fileName = seIngresoParametro_io("-i", argc, argv);
  output_fileName = seIngresoParametro_io("-o", argc, argv);
  bufferIn = seIngresoParametro_buf("-I", argc, argv);
  bufferOut = seIngresoParametro_buf("-O", argc, argv);
  printf("%s  %s  %zu  %zu\n", input_fileName, output_fileName, bufferIn, bufferOut);
  FILE* input_file = NULL;
  FILE* output_file = NULL;
  if (aperturaDeArchivos(input_fileName, &input_file, output_fileName, &output_file) == -1) {
  	if (fprintf(stderr, "Alguno de los archivos ingresados no pudo ser abierto.\n") < 0){
	fprintf(stderr, "Fallo en la ejecucion de la funcion fprintf o printf");
	}
  	return -1;
  }
  int ifd = fileno(input_file);
  int ofd = fileno(output_file);

  return palindrome(ifd, bufferIn, ofd, bufferOut); //ACA LLAMAMOS A LA FUNCION PALINDROME DE MIPS
}

