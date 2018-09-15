#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/time.h>


void genRandomString(char *str,int length)
{
  for(int i=0;i<length-1;++i)
  {
    str[i] = 'a' + rand()%26;
  }
  str[length-1] = '\0';
}
void genRandomSubString(char *str,int length,int sub_len)
{
  for(int i=0;i<length-1;++i)
  {
    if(i>0 && ((i+1)%sub_len==0)) str[i] = '\0';
    else str[i] = 'a' + rand()%26;
  }
  str[length-1] = '\0';
}

/*__global__ void my_strstr(char *str,char *sub_string,char ** position,int str_len,int sub_len,int num_sub)
{
  int id = threadIdx.x;
  char *sub = &sub_string[id*sub_len];
  char *string = str;
  char *a,*b;
  b = sub;
  printf("in GPU string is %s sub is %s\n",string,b);
  for(;*string != '\0';++string){
    a = string;
    if(*a == *b){
      printf("thread %d find a possible sub %s\n",id,b);
      while(*(++a) == *(++b)){
        printf("thread %d find a more and more possible sub %s\n",id,b);
        if(*(b+1) == '\0'){ 
          printf("thread %d find a sub %s\n",id,b);
          position[id] = string;
          printf("sting match in %s\n",position[id]);
        }
      }
    }
    b = sub;
  }
}*/

char * my_strstr(char *str,char *sub,int str_len,int sub_len)
{
  if(str_len < sub_len) return NULL;
  if(str_len != 0 && sub_len == 0) return NULL;
  if(str_len == 0 && sub_len == 0) return NULL;
  int m, n;
  for(int i=0;i<str_len;++i){
    m = 0;
    n = i;
    if(str[n]==sub[m]){
      while(str[++n] == sub[++m]){
        if(sub[m+1] == '\0') return str+i;
      }
    }
  }
  return NULL;
}



__global__ void my_strstr(char *str,char *sub_string,char ** position,int str_len,int sub_len,int num_sub)
{
  int id = threadIdx.x; 
  //char *sub = &sub_string[id*sub_len];
  char *result = NULL; 
  char sub[24];
  //load sub in register,great improve
  for(int i=0;i<sub_len;++i){
    sub[i] = sub_string[id*sub_len+i];}
  //best case using Shared memory
  extern __shared__ char s_string[];
  //every thread has to fetch how many values from global memory to shared memory
  int each_num = str_len/blockDim.x;
  for(int i=0;i<each_num;++i){
    s_string[i*blockDim.x+id] = str[i*blockDim.x+id];}
  if( ((each_num*blockDim.x+id) < str_len) && (blockDim.x > each_num) )
    s_string[each_num*blockDim.x+id] = str[each_num*blockDim.x+id];

  char *string = s_string;
  char *a,*b;
  //b point to the sub address in register rather than in global memory
  b = sub;
  //result == NULL to judge if we find a match;rather than use goto or break in loop which harm the calculation
  for(int i = 0;(*string != '\0')&&(result == NULL);i++){
    //printf("i am %d\n",id);
    a = string;
    while(*a++ == *b++){
      if(*(b+1) == '\0'){ 
        result = string;
      }
    }
    b = sub;
    ++string;
  }
  //coalesced global memory store, no effect since we only store once 
  position[id] = result;
}




int main()
{
  int LENGTH = 4096, len = 24, num_sub = 100;
  int num_block,num_thread;
  if(num_sub < 512){
    num_block = 1;
    num_thread = num_sub;
  }
  else{
    num_block = num_sub / 512;
    num_thread = 512;
  }
  char haystack[LENGTH];
  char subs[num_sub*len];
  char *position[num_sub];
  char *h_position[num_sub];
  genRandomString(haystack,LENGTH);
  genRandomSubString(subs,len*num_sub,len);

  char *d_string,*d_subs;
  char **d_position;
  cudaMalloc((void**)&d_string,sizeof(char)*LENGTH);
  cudaMalloc((void**)&d_subs,sizeof(char)*num_sub*len);
  cudaMalloc((void***)&d_position,sizeof(char*)*num_sub);
  cudaMemset(d_position,0,sizeof(char*)*num_sub);
  memset(h_position,0,sizeof(char*)*num_sub);
  const size_t smem = sizeof(char)*LENGTH;
  char h_subs[num_sub][len];
  for(int i=0;i<num_sub;++i){
    for(int j=0;j<len;++j){
      h_subs[i][j] = subs[i*len+j];
    }
  }
    
  /*CPU*/

  char *ret;
  struct timeval start,end;
  gettimeofday(&start, NULL );
  for(int i=0;i<num_sub;++i)
  {
    ret = my_strstr(haystack,h_subs[i],LENGTH,len);
    if(ret != NULL){
      printf("find one sub string in %d sub\n",i);
      printf("%s\n",ret);
    }
    position[i] = ret;
  }
  gettimeofday(&end, NULL );
  float timeuse =1000000 * ( end.tv_sec - start.tv_sec ) + end.tv_usec - start.tv_usec;
  printf("CPU time=%f\n",timeuse /1000.0);
  
  /*GPU*/

  gettimeofday(&start, NULL );
  for(int i=0;i<50;++i)
  {
    cudaMemcpy(d_string,haystack,sizeof(char)*LENGTH,cudaMemcpyHostToDevice);
    cudaMemcpy(d_subs,subs,sizeof(char)*num_sub*len,cudaMemcpyHostToDevice);
    my_strstr<<<num_block,num_thread,smem>>>(d_string,d_subs,d_position,LENGTH,len,num_sub);
    cudaDeviceSynchronize();
    cudaMemcpy(h_position,d_position,sizeof(char*)*num_sub,cudaMemcpyDeviceToHost);
  }
  gettimeofday(&end, NULL );
  timeuse =1000000 * ( end.tv_sec - start.tv_sec ) + end.tv_usec - start.tv_usec;
  printf("GPU time=%f\n",timeuse /1000.0/50);

  /*check*/

  //in small size GPU works well
  /*for(int i=0;i<num_sub;++i){
    if(h_position[i] == position[i]){
      printf("ok in %d sub\n",i);
      if(position[i] != NULL){
        printf("%s\n",position[i]);
      }
    }
    else{
      printf("error !!!!!!");
      if(position[i] != NULL){
        printf("CPU find match %s\n",position[i]);}
      //because h_position[i] point to the address in GPU , causing segment error
      if(h_position[i] != NULL){
        printf("GPU find match %s\n",h_position[i]);}
    }
  }*/

  return(0);
}
