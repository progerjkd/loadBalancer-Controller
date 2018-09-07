echo -n "CPU UTILIZATION IN %: "
zabbix_get -s 200.129.20.211 -k system.cpu.util[,,avg1] 
