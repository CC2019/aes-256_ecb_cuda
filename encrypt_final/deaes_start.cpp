#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#ifndef uint8_t
#define uint8_t  unsigned char
#endif
     
extern "C" char* gpu_decrypt(char* akey,char* plain,int length); //注意这里的声明
int main(int argc, char *argv[])
{
    char *key = "bd5767b5c272dd72bd72123123121231";
    char * plain;
    FILE* file;
    file = fopen("cipher.txt", "r");
    int numbytes;
    fseek(file, 0L, SEEK_END);
    numbytes = ftell(file);
    fseek(file, 0L, SEEK_SET);
    fread(plain, 1, numbytes, file);
    char* string = gpu_decrypt(key,plain,numbytes);
    return 0;
}
