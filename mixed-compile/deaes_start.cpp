#include <iostream>
using namespace std;
     
extern "C" int func_de(int argc, char *argv[]); //注意这里的声明
int main(int argc, char *argv[])
{
    func_de(argc,argv);
    return 0;
}
