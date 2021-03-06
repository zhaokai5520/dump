
#!/bin/bash
cat>/app/logs/JMXCONN.java<<EOF
import java.util.ArrayList;
import java.util.Set;

import javax.management.MBeanServerConnection;
import javax.management.ObjectName;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;

public class JMXCONN {
        private static ArrayList<String> db = new ArrayList<String>();          
        private static ArrayList<String> pool = new ArrayList<String>();
        private static ArrayList<ObjectName> GenericObjectPool = new ArrayList<ObjectName>();
        private static ArrayList<ObjectName> DruidDataSource = new ArrayList<ObjectName>();
        private static float connect_maxcon;
        private static float busythread_threadcount;
        private static float openfiledesc_maxfiledesc;
        private static ArrayList<Float> activecount_maxactive = new ArrayList<Float>();
        private static ArrayList<Float> active_total = new ArrayList<Float>();
        private static boolean flag;
        private static int am;
        private static int at;
        private static final float BASE=0.90f;
        
        public static void main(String[] args) throws Exception {
                String jmxURL = "service:jmx:rmi:///jndi/rmi://127.0.0.1:1099/jmxrmi";

                JMXServiceURL serviceURL = new JMXServiceURL(jmxURL);

                JMXConnector connector = JMXConnectorFactory.connect(serviceURL,null);
                MBeanServerConnection mbsc = connector.getMBeanServerConnection();
                
                Set<ObjectName> objectNames = mbsc.queryNames(null, null);
                for (ObjectName obj : objectNames) {
                        String objectnames = obj.toString();
                        if (objectnames.indexOf("id=") != -1) {
                                db.add(objectnames);
                        }
                        if (objectnames.indexOf("GenericObjectPool") != -1) {
                                pool.add(objectnames);
                        }
                }
                
                /*======================Tomcat==========================*/;
                ObjectName ThreadPool = new ObjectName("Tomcat:type=ThreadPool,name=\"http-nio-8888\"");
                String currentThreadCount = mbsc.getAttribute(ThreadPool, "currentThreadCount").toString();
                String maxConnections = mbsc.getAttribute(ThreadPool, "maxConnections").toString();
                String connectionCount = mbsc.getAttribute(ThreadPool, "connectionCount").toString();
                String currentThreadsBusy = mbsc.getAttribute(ThreadPool, "currentThreadsBusy").toString();
                if (Integer.valueOf(maxConnections) != 0) {
                        connect_maxcon = (float)Integer.valueOf(connectionCount) / (float)Integer.valueOf(maxConnections);
                }
                if (Integer.valueOf(currentThreadCount) != 0) {
                        busythread_threadcount = (float)Integer.valueOf(currentThreadsBusy) / (float)Integer.valueOf(currentThreadCount);
                }
                
                /*======================Druid==========================*/
                /*db*/
                for (int index=0; index <= db.size()-1; index++) {
                        DruidDataSource.add(new ObjectName(db.get(db.size()-1)));
                        String ActiveCount = mbsc.getAttribute(DruidDataSource.get(index), "ActiveCount").toString();
                        String MaxActive = mbsc.getAttribute(DruidDataSource.get(index), "MaxActive").toString();
                        if (Integer.valueOf(MaxActive) != 0 ) {
                                activecount_maxactive.add((float)Integer.valueOf(ActiveCount) / (float)Integer.valueOf(MaxActive));
                        }
                }
                
                /*======================OperatingSystem==========================*/
                ObjectName OperatingSystem = new ObjectName("java.lang:type=OperatingSystem");
                String OpenFileDescriptorCount = mbsc.getAttribute(OperatingSystem, "OpenFileDescriptorCount").toString();
                String MaxFileDescriptorCount = mbsc.getAttribute(OperatingSystem, "MaxFileDescriptorCount").toString();
                if (Integer.valueOf(MaxFileDescriptorCount) != 0) {
                        openfiledesc_maxfiledesc = (float)Integer.valueOf(OpenFileDescriptorCount) / (float)Integer.valueOf(MaxFileDescriptorCount);
                }

                /*======================GenericObjectPool==========================*/
                /*redis*/
                for (int index=0; index <= pool.size()-1; index++) {
                        GenericObjectPool.add(new ObjectName(pool.get(index)));
                        String MaxTotal = mbsc.getAttribute(GenericObjectPool.get(index), "MaxTotal").toString();
                        String NumActive = mbsc.getAttribute(GenericObjectPool.get(index), "NumActive").toString();
                        if (Integer.valueOf(MaxTotal) != 0) {
                                active_total.add((float)Integer.valueOf(NumActive) / (float)Integer.valueOf(MaxTotal));
                        }
                }       
                
                for (int i=0; i<=activecount_maxactive.size()-1; i++) {
                        if (activecount_maxactive.get(i) >= BASE) {
                                am += 1;
                        }
                }
                
                for (int i=0; i<=active_total.size()-1; i++) {
                        if (active_total.get(i) >= BASE) {
                                at += 1;
                        }
                }
                
                if ((busythread_threadcount ) >= BASE || (openfiledesc_maxfiledesc ) >= BASE || am != 0 || at != 0) {
                        flag = true;
                }
                System.out.println(flag);
				System.out.println("ActiveCount/MaxActive=" + activecount_maxactive);
				System.out.println("NumActive/MaxTotal=" + active_total);
				System.out.println("connectionCount/maxConnections=" + connect_maxcon);
				System.out.println("currentThreadsBusy/currentThreadCount=" + busythread_threadcount);
				System.out.println("OpenFileDescriptorCount/MaxFileDescriptorCount=" + openfiledesc_maxfiledesc);		
        }

}
EOF


	DUMP_NUM=3
	CPU_USE=400

#read  -p "请输入CPU_USE的值：" CPU_USE
if [ ! -n "$1" ];then
       CPU_USE=400
else
     CPU_USE="$1"
    fi
#echo "$CPU_USE"
#if [ -z "${CPU_USE}" ];then        #如果CPU_USE为空
#	CPU_USE=400
#fi
#echo "CPU_USE的值是  $CPU_USE"


##	
if [ -f /data/env/jdk_version ] ; then                                                                                                                                                                 
    JDK=jdk`cat /data/env/jdk_version`                                                                                                                                                                 
else                                                                                                                                                                                                   
    JDK=jdk1.7.0_65                                                                                                                                                                                    
fi 
export JAVA_HOME=/app/jdk/$JDK  #输入JDK的路径

JPS_NUM=$(${JAVA_HOME}"/bin/jps" | grep -v "Jps" | grep -v "AgentServer" | wc -l)

if [[ ! -z "/app/logs/dump/" ]];
then
        mkdir -p /app/logs/dump/     
        chmod 777 /app/logs/dump/    #设置所有人可以读写及执行
fi

if [[ ! -z "/app/logs/thread/" ]];
then 
        mkdir -p /app/logs/thread/
        chmod 777 /app/logs/thread/ 
fi

if [[ -f "/app/logs/JMXCONN.class" ]];
then 
b=`stat -c %Y /app/logs/JMXCONN.class`   #将文件JMXCONN.class修改时间赋值给b
a=`date +%s`			#从 1970 年 1 月 1 日 00:00:00 UTC 到目前为止的秒数（时间戳）
	if [ $[ $a - $b ] -gt 86400 ];     #判断java文件编译时间是否大于一天，86400/60/60/=24
	then
		if [[ -f "/app/logs/JMXCONN.java" ]];
		then 
        cd /app/logs/
        ${JAVA_HOME}"/bin/javac" /app/logs/JMXCONN.java
		fi
	fi
else
	if [[ -f "/app/logs/JMXCONN.java" ]];
	then 
    cd /app/logs/
    ${JAVA_HOME}"/bin/javac" /app/logs/JMXCONN.java
	fi
fi


if [[ ! -f "/app/logs/JMXCONN.class" ]];
then 
        exit -1
fi



#CreateJavaDump
function CreateJavaDump() {
        echo "creating...."
		for (( i=1; i<=${JPS_NUM}; i++ ))
        do
                pid=$(${JAVA_HOME}"/bin/jps" | grep -v "Jps" | grep -v "AgentServer"| sed -n "${i}p" | awk '{print $1}')  #grep 反转查找 awk 文本分析
                filename="/app/logs/thread/${pid}.top1.$(date +%Y-%m-%d-%H%M%S).log"
                /usr/bin/top -H -p ${pid} -bn 1 > $filename  #-bn获取top第一行
				cpu_used=$(grep java $filename|awk '{s1+=$9}END{print s1}'|awk -F '.' '{print $1}')
                cd /app/logs
				result=$(${JAVA_HOME}"/bin/java" JMXCONN)
				date >>dump_stat
				echo $result >>dump_stat
				result_ans=`echo $result |awk '{print $1}'`
				
		

		
		}
		
		
		
		
		
		
		