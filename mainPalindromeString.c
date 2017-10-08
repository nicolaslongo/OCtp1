#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>

int palindromeString(char* palabra, size_t tamanioPalabra);

int main(int argc, char** argv)
{
	palindromeString("111", 2);
	
	return 0;
}

