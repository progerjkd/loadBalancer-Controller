echo -n "Total: " 
TOTAL=`zabbix_get -s 200.129.20.211 -k vm.memory.size[total]` 
TOTAL=`expr $TOTAL / 1024 / 1024`
echo $TOTAL

echo -n "Buffers: " 
BUFFERS=`zabbix_get -s 200.129.20.211 -k vm.memory.size[buffers]`
BUFFERS=`expr $BUFFERS / 1024 / 1024`
echo $BUFFERS

echo -n "Cached: " 
CACHED=`zabbix_get -s 200.129.20.211 -k vm.memory.size[cached]`
CACHED=`expr $CACHED / 1024 / 1024`
echo $CACHED

echo -n "FREE: " 
FREE=`zabbix_get -s 200.129.20.211 -k vm.memory.size[free]`
FREE=`expr $FREE / 1024 / 1024`
echo $FREE

echo -n "USED: " 
USED=`zabbix_get -s 200.129.20.211 -k vm.memory.size[used]`
USED=`expr $USED / 1024 / 1024`
echo $USED

echo -n "USED - CACHED & BUFFERS: "
USEDC=`expr $USED - $BUFFERS - $CACHED`
echo $USEDC


echo -n "MEMORY USED IN %: "
expr \( $USED \* 100 \) / $TOTAL

echo -n "MEMORY USED - CACHED & BUFFERS IN %: "
expr \( $USEDC \* 100 \) / $TOTAL




        TOTAL_MEM=`zabbix_get -s 200.129.20.211 -k vm.memory.size[total]`
        TOTAL_MEM=`expr $TOTAL_MEM / 1024 / 1024`
        #echo "Total memory: $TOTAL_MEM MB"

        BUFFERS_MEM=`zabbix_get -s 200.129.20.211 -k vm.memory.size[buffers]`
        BUFFERS_MEM=`expr $BUFFERS_MEM / 1024 / 1024`
        #echo "Used memory in buffers: $BUFFERS_MEM MB"

        CACHED_MEM=`zabbix_get -s 200.129.20.211 -k vm.memory.size[cached]`
        CACHED_MEM=`expr $CACHED_MEM / 1024 / 1024`
        #echo "Used memory in cache: $CACHED_MEM MB"

        USED_MEM=`zabbix_get -s 200.129.20.211 -k vm.memory.size[used]`
        USED_MEM=`expr $USED_MEM / 1024 / 1024`
        echo "Used memory (+buffers +cache): $USED_MEM MB"

        USED_BC_MEM=`expr $USED_MEM - $BUFFERS_MEM - $CACHED_MEM`
        echo -n "Used memory (-buffers -cache): $USED_BC_MEM MB"

	echo
        PERC_MEM=`expr \( $USED_MEM \* 100 \) / $TOTAL_MEM`
        echo -n "Used memory in (+buffers +cache) %: $PERC_MEM"

	echo aaa
expr \( $USED_MEM \* 100 \) / $TOTAL_MEM
E=`expr \( $USED_MEM \* 100 \) / $TOTAL_MEM`
echo $E
