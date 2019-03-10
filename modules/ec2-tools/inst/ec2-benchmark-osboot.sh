#!/bin/sh
#
# Benchmark AWS EC2 - Operating System's startup time in seconds.
# Measured as time between instance state reported as "running"
# and SSH availability.
# For higher precision, several cycles should be run and averaged.
#
# (cloux@rote.ch)

# your aws-cli profile
profile="default"
# how many boot cycles
cycles=5

###############################################################

instance_id="$1"
if [ -z "$instance_id" ]; then
  echo "Usage: ec2-benchmark-osboot.sh INSTANCE-ID"
  exit
fi

# fill instance_* global info variables
get_instance_info () {
	INSTANCE_INFO=$(aws ec2 describe-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null)
	instance_type=$(echo "$INSTANCE_INFO" | grep 'INSTANCES\s' | cut -f 10)
	instance_subnet=$(echo "$INSTANCE_INFO" | grep 'PLACEMENT\s' | cut -f 2)
	instance_state=$(echo "$INSTANCE_INFO" | grep 'STATE\s' | cut -f 3)
	instance_uri=$(echo "$INSTANCE_INFO" | grep 'INSTANCES\s' | cut -f 15)
}

start_instance () {
	printf "Start instance ... "
	aws ec2 start-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null >/dev/null
	while true; do
		get_instance_info
		[ "$instance_state" = "running" ] && break
		sleep 0.1
	done
	echo "OK"
}

get_instance_URI () {
	if [ -z "$instance_uri" ]; then
		echo "Wait for URI ... "
		while [ -z "$instance_uri" ]; do
			get_instance_info
			sleep 0.1
		done
		echo "OK"
	fi
	if [ "$(printf "%s" "$instance_uri" | grep 'compute.*\.amazonaws\.com')" ]; then
		echo " Instance URI: $instance_uri"
	else
		echo "Error: invalid instance URI: $instance_uri"
		exit
	fi
}

wait_for_ssh () {
	printf "  Wait for SSH "
	while true; do
		#nc -w 1 -4z "$instance_uri" 22 2>/dev/null >/dev/null; [ $? -eq 0 ] && break
		[ "$(ssh-keyscan -4 -T 1 "$instance_uri" 2>/dev/null)" ] && break
		printf "."
	done
	echo " OK"
}

stop_instance () {
	printf " Stop instance ... "
	aws ec2 stop-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null >/dev/null
	while [ "$instance_state" != "stopped" ]; do
		get_instance_info
		sleep 0.2
	done
	echo "OK"
}

##
## Benchmark
##

# check instance state
get_instance_info
if [ "$instance_state" != "stopped" ]; then
	if [ -z "$instance_state" ]; then
		echo  "Instance $instance_id not found in AWS '$profile' profile."
	else
		printf "Instance %s is %s.\n" "$instance_id" "$instance_state"
		printf "Stop the instance and then start the benchmark again.\n"
	fi
	exit
fi

echo "=========================================="
echo "Benchmarking instance: $instance_id"
echo "                 Type: $instance_type"
echo "               Subnet: $instance_subnet"
echo "=========================================="
for i in $(seq 1 $cycles); do
	echo "   Boot cycle: $i of $cycles"
	start_instance
	START=$(date +%s.%N)
	get_instance_URI
	wait_for_ssh
	END=$(date +%s.%N)
	stop_instance
	printf "  Bootup Time: \033[1;95m%s\033[0m sec\n" "$(echo "scale=1; ($END - $START)/1" | bc)"
	echo "=========================================="
done


