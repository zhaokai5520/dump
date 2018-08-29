# dump

chmod:控制文件如何被他人所调用,改变文件权限
chmod [-cfvR] [--help] [--version] mode file...
+ 表示增加权限、- 表示取消权限、= 表示唯一设定权限。
r 表示可读取，w 表示可写入，x 表示可执行，X 表示只有当该文件是个子目录或者该文件已经被设定过为可执行。
chmod 777 file  设置所有人可以读写及执行
chmod 600 file  设置拥有者可读写，其他人不可读写执行


变量	含义
$0		当前脚本的文件名
$n	传递给脚本或函数的参数。如，第一个参数是$1
$#	传递给脚本或函数的参数个数
$*	传递给脚本或函数的所有参数
$@	传递给脚本或函数的所有参数。被双引号(” “)包含时，与 $* 稍有不同
$?	上个命令的退出状态，或函数的返回值。成功返回0，失败返回1
$$	当前Shell进程ID。对于 Shell 脚本，就是这些脚本所在的进程ID
传入参数例子：
if [ ! -n "$1" ];then
       CPU_USE=400
else
     CPU_USE="$1"
    fi


shell常见比较字符
-eq   等于				-ne    不等于					-gt    大于
-lt    小于				-le    小于等于				-ge   大于等于
-z    空串				=    两个字符相等				!=    两个字符不等
-n    非空串

jps(Java Virtual Machine Process Status Tool)是JDK1.5提供的一个显示当前所有java进程pid的命令。显示当前系统的java进程情况及进程id
使用方法：在当前命令行下打jps(jps存放在JAVA_HOME/bin/jps，使用时为了方便请将JAVA_HOME/bin/加入到Path) 。
	
	
	
	
	
	