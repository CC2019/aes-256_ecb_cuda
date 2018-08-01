# aes-256_ecb_cuda
aes-ecb在gpu上的实现
aes-ecb在gpu上的实现 程序分为两部分——加密和解密 编译方式非常简单 nvcc aes_128.cu -o gpu nvcc deaes.cu -o deaes 执行方式为./gpu [keyfile] [input] 其中keyfile必须要添加，程序要从中读取密钥（32字节），input文件的缺省文件为input.txt 执行结果为产生一个cipher.txt文件，保存加密后的信息 执行deaes的方法相同， ./deaes key文件 output（缺省为output.txt） 执行结果为产生一个output.txt文件保存解码后的信息

padding的内容为0x00，padding长度信息保存在cipher.txt的末尾，以int方式追加，4字节 需要注意的问题是每次从input.txt文件中读取信息时都会读入一个换行符0x0a，这个不影响output.txt的显示，但是可能影响cipher.txt的内容和最终解码后比特流

由于上一个aes-128程序存在诸多问题，在多次修改后我无奈选择了放弃... 和上一个aes-128的程序相比，这个版本的程序的并发行更好，更加安全。
