#include <iostream>
using namespace std;
     
extern "C" char* gpu_decrypt(char* akey,char* plain); //注意这里的声明
int main(int argc, char *argv[])
{
    char *key = "bd5767b5c272dd72bd72123123121231";
    char * plain = "1241242131231";
    char* string = gpu_decrypt(key,plain);
    return 0;
}
