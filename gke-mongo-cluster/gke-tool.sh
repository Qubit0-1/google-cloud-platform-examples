#!/bin/bash

function exec_cmd
{	
	echo "execute:   $EXEC_SCRIPT"
	if [ "$ARG_DRY_RUN" = 0 ]; then
		bash -c "$EXEC_SCRIPT";
	fi

}

function clear_workspace_folder
{
	EXEC_SCRIPT="rm -Rf ./tmp-ws"
	bash -c "$EXEC_SCRIPT";
}

function create_disk
{
	for element in "${array[@]}"
	do
		EXEC_SCRIPT="gcloud compute disks create --size 500GB disk-$element"
		exec_cmd
	done
}

function delete_disk
{
	for element in "${array[@]}"
	do
		EXEC_SCRIPT="gcloud compute disks delete disk-$element -q"
		exec_cmd
	done
}

function create_replica_set
{
	rs_set="${array[0]}"
	mg_a="${array[1]}"
	mg_b="${array[2]}"
	mg_c="${array[3]}"
	
	# prepare pods magnifest file
	sed "s/{tagname}/$mg_a/g" ./templates/pod-member-{tagname}.json | sed "s/--replSet {replica-name}/--replSet $rs_set/g" > ./tmp-ws/pod-$mg_a.json
	sed "s/{tagname}/$mg_b/g" ./templates/pod-member-{tagname}.json | sed "s/--replSet {replica-name}/--replSet $rs_set/g" > ./tmp-ws/pod-$mg_b.json
	sed "s/{tagname}/$mg_c/g" ./templates/pod-member-{tagname}.json | sed "s/--replSet {replica-name}/--replSet $rs_set/g" > ./tmp-ws/pod-$mg_c.json
	
	# prepare service magnifest file
	sed "s/{tagname}/$mg_a/g" ./templates/svc-member-{tagname}.json > ./tmp-ws/svc-$mg_a.json
	
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/pod-$mg_a.json"
	exec_cmd
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/pod-$mg_b.json"
	exec_cmd
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/pod-$mg_c.json"
	exec_cmd
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/svc-$mg_a.json"
	exec_cmd
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/svc-$mg_b.json"
	exec_cmd
	EXEC_SCRIPT="kubectl create -f ./tmp-ws/svc-$mg_c.json"
	exec_cmd
	
	echo "todo todo..."
}


function delete_container
{
	for element in "${array[@]}"
	do
		EXEC_SCRIPT="kubectl delete services $element"
		exec_cmd
		
		sleep 1
		
		EXEC_SCRIPT="kubectl delete pods $element"
		exec_cmd
	done
}


function create_config_server
{
	echo "todo todo..."
}

function create_router
{
	echo "todo todo..."
}

function clean
{
	echo "todo todo..."
}

### main ###########

# Execute getopt
ARGS=$(getopt -o c:n:dk --long command:,names:,dry-run,keep-workspace -n "getopt.sh" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
  exit 1
fi

ARG_CMD=
ARG_NAMES=
ARG_DRY_RUN=0
ARG_KEEP_WORKSPACE=0
EXEC_SCRIPT=

eval set -- "$ARGS";

while true; do
  case "$1" in
    -c|--command) ARG_CMD=$2 ; shift 2; ;;
    -n|--names) ARG_NAMES=$2 ; shift 2; ;;
    -d|--dry-run) ARG_DRY_RUN=1 ; shift ; ;;
    -k|--keep-workspace) ARG_KEEP_WORKSPACE=1 ; shift ; ;;
    --)
      shift;
      break;
      ;;
  esac
done

echo "ARG_CMD: $ARG_CMD";
echo "ARG_NAMES: $ARG_NAMES";
echo "ARG_DRY_RUN: $ARG_DRY_RUN";
echo "ARG_KEEP_WORKSPACE: $ARG_KEEP_WORKSPACE";

IFS=',' read -a array <<< "$ARG_NAMES"

clear_workspace_folder

mkdir -p ./tmp-ws

if [ "$ARG_CMD" = "create_disk" ]; then
	create_disk
elif [ "$ARG_CMD" = "create_replica_set" ]; then
	create_replica_set
elif [ "$ARG_CMD" = "create_config_server" ]; then
	create_config_server
elif [ "$ARG_CMD" = "create_router" ]; then
	create_router
elif [ "$ARG_CMD" = "delete_disk" ]; then
	delete_disk
elif [ "$ARG_CMD" = "delete_service" ]; then
	create_replica_set
elif [ "$ARG_CMD" = "delete_container" ]; then
	delete_container
elif [ "$ARG_CMD" = "clean" ]; then
	clean
else
	echo "unknown command"
fi

if [ "$ARG_KEEP_WORKSPACE" = 0 ]; then
	clear_workspace_folder
fi
