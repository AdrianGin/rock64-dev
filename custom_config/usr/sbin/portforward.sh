#!/bin/sh

case "$1" in
  --help)
	printf "portforward.sh [single/multi] [tcp/udp] [input interface] [input ip] [input port:ports] [out iface] [out ip] [out port:ports]"
	;;	

       single)
	PROT=$2
	INPUT_FACE=$3
	INPUT_IP=$4
	INPUT_PORTS=$5
	OUTPUT_IFACE=$6
	OUTPUT_IP=$7
	OUTPUT_PORTS=$8
	
	iptables -t nat -A PREROUTING -i $INPUT_FACE -d $INPUT_IP -p $PROT --dport $INPUT_PORTS -j DNAT --to-destination $OUTPUT_IP:$OUTPUT_PORT
	iptables -t nat -A POSTROUTING  -o $OUTPUT_IFACE -d $OUTPUT_IP -p $PROT --dport $OUTPUT_PORTS -j SNAT --to-source $INPUT_IP
	;;

       multi)
	PROT=$2
	INPUT_FACE=$3
	INPUT_IP=$4
	INPUT_PORTS=$5
	OUTPUT_IFACE=$6
	OUTPUT_IP=$7
	OUTPUT_PORTS=$8
	
	iptables -t nat -A PREROUTING -i $INPUT_FACE -d $INPUT_IP -p $PROT --dports $INPUT_PORTS -j DNAT --to-destination $OUTPUT_IP:$OUTPUT_PORT
	iptables -t nat -A POSTROUTING  -o $OUTPUT_IFACE -d $OUTPUT_IP -p $PROT --dports $OUTPUT_PORTS -j SNAT --to-source $INPUT_IP
	;;

esac


exit 0


