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
  printf 'Usage: ec2-benchmark-osboot.sh INSTANCE-ID\n'
  exit
fi

# fill instance_* global info variables
get_instance_info () {
	INSTANCE_INFO=$(aws ec2 describe-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null)
	instance_type=$(printf '%s' "$INSTANCE_INFO" | grep 'INSTANCES\s' | cut -f 10)
	instance_subnet=$(printf '%s' "$INSTANCE_INFO" | grep 'PLACEMENT\s' | cut -f 2)
	instance_state=$(printf '%s' "$INSTANCE_INFO" | grep 'STATE\s' | cut -f 3)
	instance_uri=$(printf '%s' "$INSTANCE_INFO" | grep 'INSTANCES\s' | cut -f 15)
}

start_instance () {
	printf 'Start instance ... '
	aws ec2 start-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null >/dev/null
	while true; do
		get_instance_info
		[ "$instance_state" = "running" ] && break
		sleep 0.1
	done
	printf 'OK\n'
}

get_instance_URI () {
	if [ -z "$instance_uri" ]; then
		printf 'Wait for URI ... '
		while [ -z "$instance_uri" ]; do
			get_instance_info
			sleep 0.1
		done
		echo 'OK\n'
	fi
	if [ "$(printf '%s' "$instance_uri" | grep 'compute.*\.amazonaws\.com')" ]; then
		printf ' Instance URI: %s\n' "$instance_uri"
	else
		printf 'Error: invalid instance URI: %s\n' "$instance_uri"
		exit
	fi
}

wait_for_ssh () {
	printf '  Wait for SSH '
	while true; do
		#nc -w 1 -4z "$instance_uri" 22 2>/dev/null >/dev/null; [ $? -eq 0 ] && break
		[ "$(ssh-keyscan -4 -T 1 "$instance_uri" 2>/dev/null)" ] && break
		printf '.'
	done
	printf ' OK\n'
}

stop_instance () {
	printf ' Stop instance ... '
	aws ec2 stop-instances --profile $profile --instance-ids="$instance_id" 2>/dev/null >/dev/null
	while [ "$instance_state" != "stopped" ]; do
		get_instance_info
		sleep 0.2
	done
	printf 'OK\n'
}

##
## Benchmark
##

# check instance state
get_instance_info
if [ "$instance_state" != "stopped" ]; then
	if [ -z "$instance_state" ]; then
		printf 'Instance %s not found in AWS "%s" profile.\n' "$instance_id" "$profile"
	else
		printf 'Instance %s is %s.\n' "$instance_id" "$instance_state"
		printf 'Stop the instance and then start the benchmark again.\n'
	fi
	exit
fi

printf '==========================================\n'
printf 'Benchmarking instance: %s\n' "$instance_id"
printf '                 Type: %s\n' "$instance_type"
printf '               Subnet: %s\n' "$instance_subnet"
printf '==========================================\n'
for i in $(seq 1 $cycles); do
	printf '   Boot cycle: %s of %s\n' "$i" "$cycles"
	start_instance
	START=$(date +%s.%N)
	get_instance_URI
	wait_for_ssh
	END=$(date +%s.%N)
	stop_instance
	printf '  Bootup Time: \033[1;95m%s\033[0m sec\n' "$(printf 'scale=1; (%s - %s)/1\n' "$END" "$START" | bc)"
	printf '==========================================\n'
done
