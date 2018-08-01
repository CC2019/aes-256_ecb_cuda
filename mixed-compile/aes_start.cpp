#include <iostream>
using namespace std;
     
extern "C" int func(int argc, char *argv[]); //注意这里的声明
int main(int argc, char *argv[])
{
    func(argc,argv);
    return 0;
}
