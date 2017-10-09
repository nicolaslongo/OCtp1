#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>

int esEspacio(char c);

int main(int argc, char** argv)
{
	char* v = "a'-_9/@K.<";
	int i;
	for(i = 0; i< 10; i++){
		if (esEspacio(v[i])){
			printf("%c es espacio\n", v[i]);
		}
		else{
			printf("%c es caracter\n", v[i]);
		}
	}	
	return 0;
}
