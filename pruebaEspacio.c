#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>

int esEspacio(char c);

int main(int argc, char** argv)
{
	char* v = "aaab'-_9/@K.<";
	int i;
	int cond;
	for(i = 0; i< 13; i++){
		cond = esEspacio(v[i]);
		if (cond == 1){
			printf("%c es espacio\n", v[i]);
		}
		else { 
			if(cond == 0) {
			printf("%c es caracter\n", v[i]);
			}
			else{
			printf("Con %c se fue todo a la puta\n", v[i]);
			}
		}
	}	
	return 0;
}
