#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#ifndef uint8_t
#define uint8_t  unsigned char
#endif

#ifdef __cplusplus
extern "C" { 
#endif
/*
typedef struct {
  uint8_t key[32]; 
  uint8_t enckey[32]; 
  uint8_t deckey[32];
} aes256_context;
*/

#ifdef __cplusplus
}
#endif
#define AES_BLOCK_SIZE 16
#define THREADS_PER_BLOCK 512

     
extern "C" int gpu_encrypt(char *akey, char *plain,int length,char* cipher); //注意这里的声明
int main(int argc, char *argv[])
{
  FILE *file;
  char *key = "bd5767b5c272dd72bd72123123121231";
  char *plain = "123123";
  char * cipher;
  int len;
  len = gpu_encrypt(key,plain,strlen(plain),cipher);
  printf("finished!\n");
    return 0;
}
