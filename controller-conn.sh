#!/bin/bash

CHANGED=0
MAX_INSTANCES_NUM=17
LOG="controller.log"
MIN_INSTANCES_NUM=1

EUCA="200.129.20.202"
NGINX="200.129.20.210"
EXEC="ssh root@$EUCA"

if [ $1 ]; then
	START_TIME_STAMP=$1
fi


echo -e "\n#####################################################" >> $LOG

INSTANCES_LIST=`$EXEC euca-describe-instances  --filter image-id=emi-43033F07 --filter instance-state-name=running | grep INSTANCE| awk {'print $2'}`
INSTANCES_NUM=`$EXEC euca-describe-instances  --filter image-id=emi-43033F07 --filter instance-state-name=running | grep INSTANCE| awk {'print $2'} | wc -l`

memInfo(){
	TOTAL_MEM=`zabbix_get -s $1 -k vm.memory.size[total]`
	TOTAL_MEM=`expr $TOTAL_MEM / 1024 / 1024`
#	echo "Total memory: $TOTAL_MEM MB" | tee -a $LOG

	BUFFERS_MEM=`zabbix_get -s $1 -k vm.memory.size[buffers]`
	BUFFERS_MEM=`expr $BUFFERS_MEM / 1024 / 1024`
#	echo "Used memory in buffers: $BUFFERS_MEM MB" | tee -a $LOG

	CACHED_MEM=`zabbix_get -s $1 -k vm.memory.size[cached]`
	CACHED_MEM=`expr $CACHED_MEM / 1024 / 1024`
#	echo "Used memory in cache: $CACHED_MEM MB" | tee -a $LOG

	USED_MEM=`zabbix_get -s $1 -k vm.memory.size[used]`
	USED_MEM=`expr $USED_MEM / 1024 / 1024`
#	echo "Used memory (+buffers +cache): $USED_MEM MB" | tee -a $LOG

	USED_BC_MEM=`expr $USED_MEM - $BUFFERS_MEM - $CACHED_MEM`
	echo -n "Used memory (-buffers -cache): $USED_BC_MEM MB" | tee -a $LOG

#	echo | tee -a $LOG

	PERC_MEM=`expr \( $USED_MEM \* 100 \) / $TOTAL_MEM`
#	echo -n "Used memory in (+buffers +cache) %: $PERC_MEM" | tee -a $LOG

	echo | tee -a $LOG

	PERC_BC_MEM=`expr \( $USED_BC_MEM \* 100 \) / $TOTAL_MEM`
	echo -n "Used memory in (-buffers -cache) %: $PERC_BC_MEM" | tee -a $LOG
	
	echo | tee -a $LOG

	TOTAL_LOAD_MEM=$(echo "scale = 2; $TOTAL_LOAD_MEM + $PERC_BC_MEM" | bc)
}



nginxReconfig(){

	INSTANCES_LIST=`$EXEC euca-describe-instances  --filter image-id=emi-43033F07 --filter instance-state-name=running | grep INSTANCE| awk {'print $2'}`
	EXEC_NGINX="ssh root@$NGINX"
	FILE="/etc/nginx/conf.d/upstream.conf"

	for INSTANCE in $INSTANCES_LIST; do
		IP_LIST="$IP_LIST `$EXEC euca-describe-instances $INSTANCE | grep INSTANCE| awk {'print $4'}`"
	done
		
	$EXEC_NGINX "echo \"upstream bench {\" > $FILE"

	for IP in $IP_LIST; do

		$EXEC_NGINX "echo -e \" \\t server $IP:80 max_fails=3 fail_timeout=30s; \" >> $FILE "
	done

	$EXEC_NGINX "echo \"}\" >> $FILE"
	$EXEC_NGINX "service nginx reload"
	echo "Reconfiguring Nginx..." >> $LOG


}

echo -e "Instances list:\n$INSTANCES_LIST" | tee -a $LOG
echo "Number of instances: $INSTANCES_NUM" | tee -a $LOG

TOTAL_LOAD=0
TOTAL_LOAD_MEM=0
for INSTANCE in $INSTANCES_LIST; do
	IP=`$EXEC euca-describe-instances $INSTANCE | grep INSTANCE| awk {'print $4'}`
	CPU_LOAD=`printf "%0.2f\n" \`zabbix_get -s $IP -k system.cpu.util[,,avg1]\``
	TOTAL_LOAD=$(echo "scale = 2; $TOTAL_LOAD + $CPU_LOAD" | bc)
	TIME_STAMP=$(date +%s -d "`date`")
	SECS=$(( ($TIME_STAMP - $START_TIME_STAMP) ))
	echo "IP: $IP CPU LOAD: $CPU_LOAD at `date` SECS: $SECS" | tee -a $LOG
	memInfo $IP
	echo "Number os running proccess apache2: `zabbix_get -s $IP -k proc.num[apache2]`" | tee -a $LOG
	curl -s http://$IP/server-status | grep "requests" | tee -a $LOG
	echo | tee -a $LOG

done

LOAD_MEM_AVERAGE=$(echo "scale = 2; $TOTAL_LOAD_MEM / $INSTANCES_NUM" | bc)
LOAD_AVERAGE=$(echo "scale = 2; $TOTAL_LOAD / $INSTANCES_NUM" | bc)

TIME_STAMP=$(date +%s -d "`date`")
SECS=$(( ($TIME_STAMP - $START_TIME_STAMP) ))
echo "Total load: $TOTAL_LOAD" | tee -a $LOG
echo "Load average: $LOAD_AVERAGE SECS: $SECS" | tee -a $LOG
echo "Memory load average: $LOAD_MEM_AVERAGE" | tee -a $LOG
CONNECTIONS=`links -dump http://bench.uvanet.br/nginx_status | grep Active| awk  '{ print $3}'`
echo "Number of active connections: $CONNECTIONS" | tee -a $LOG

if  (( $(bc <<< "$CONNECTIONS > 80") == 1 )); then

	if [ $INSTANCES_NUM -lt $MAX_INSTANCES_NUM ]; then
		CHANGED=1
		TIME_STAMP=$(date +%s -d "`date`")
		SECS=$(( ($TIME_STAMP - $START_TIME_STAMP) ))
		echo "Starting a new instance at `date` SECS: $SECS ..." | tee -a $LOG
		$EXEC "source /root/credentials/demo/eucarc && euca-run-instances emi-43033F07 -k admin -t m1.small"
		echo "Waiting 60s..." | tee -a $LOG
		sleep 60
		nginxReconfig
	else
		echo "Error: Maximum instances number reached." | tee -a $LOG
	fi

elif (( $(bc <<< "$CONNECTIONS < 30") == 1 )); then

	if [ $INSTANCES_NUM -gt $MIN_INSTANCES_NUM ]; then
		CHANGED=1
		TIME_STAMP=$(date +%s -d "`date`")
		SECS=$(( ($TIME_STAMP - $START_TIME_STAMP) ))
		echo "Removing a instance at `date` SECS: $SECS ..." | tee -a $LOG
		INSTANCE=`echo $INSTANCES_LIST | awk {'print $1'}`
		$EXEC "source /root/credentials/demo/eucarc && euca-terminate-instances $INSTANCE" 
		echo "Waiting 30s..." | tee -a $LOG
		sleep 30
		nginxReconfig
	else
		echo "Error: Minumum instances number reached." | tee -a $LOG
	fi

fi
