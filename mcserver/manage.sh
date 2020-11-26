#!/bin/bash
# using container from itzg
# https://github.com/itzg/docker-minecraft-server
# https://linuxhandbook.com/list-containers-docker/
CONFIG_PATH="/mcdata/server.config"
if [ -f "$CONFIG_PATH" ];then
    . $CONFIG_PATH
fi

show_usage()
{
    echo "Usage: $0 [options [parameters]]\n"
    echo "\n"
    echo "Options:\n"
    echo "--init [name]  , Init server container.\n"
    echo "--start        , Start container.\n"
    echo "--stop         , Stop container.\n"
    echo "--backup       , Backup server files.\n"
    echo "--restore      , Restore server files.\n"
    echo "-h:--help , Show usage.\n"
    return 0
}

init()
{
    if [ -f "$CONFIG_PATH" ];then
        echo "Server already initialized as $container_name"
    else    
        echo "container_name=$1" >> "$CONFIG_PATH"
        echo "last_backup_path=/mcdata/backups/last_backup" >> "$CONFIG_PATH"
        echo "backup_path=/mcdata/backups" >> "$CONFIG_PATH"
        echo "server_path=/mcdata/server" >> "$CONFIG_PATH"
        echo "modpacks_path=/mcdata/modpacks" >> "$CONFIG_PATH"
        echo "server_port=25565" >> "$CONFIG_PATH"
    fi
}

create()
{
    local container_id=$(docker container ls -a -q --filter "name=$container_name")
    if [ "${container_id}" == "" ];then
        docker create -v ${server_path}:/data -v ${modpacks_path}:/modpacks -p ${server_port}:25565 --name ${container_name} -e VERSION=1.16.4 -e TYPE=CURSEFORGE -e CF_SERVER_MOD=/modpacks/Valhelsia_SERVER-3.0.21.zip -e MEMORY=4G -e EULA=TRUE itzg/minecraft-server
    else
        echo "Container already exists: $container_name"
    fi
}

start()
{
    local container_id=$(docker container ls -a -q --filter "name=$container_name")
    if [ "${container_id}" == "" ];then
        echo "Could not start '$container_name'. Container does not exist."
    fi
    if [ "${container_id}" != "" ];then
        if [ "$( docker container inspect -f '{{.State.Running}}' ${container_name} )" == "true" ];then
            echo "Container '$container_name' already running."
        else
            docker start "$container_name"
            echo "Started container '$container_name'."
        fi
    fi
}

stop()
{
    local container_id=$(docker container ls -a -q --filter "name=$container_name")
    if [ "${container_id}" != "" ];then
        if [ "$( docker container inspect -f '{{.State.Running}}' $container_name )" == "true" ];then
            docker stop $container_name
        fi
    fi
}

backup_data()
{    
    local time_stamp=$(date +%Y-%m-%d-%T)
    local this_backup_path="${backup_path}/${time_stamp}"
    stop "$container_name"

    mkdir -p ${this_backup_path}
    rsync -avz ${server_path}/ ${this_backup_path} --delete 
    echo ${time_stamp} > $last_backup_path

    start "$container_name"
}

restore_data()
{
    local last_backup=$(cat $last_backup_path)    
    local this_backup_path="$backup_path/$last_backup"

    if [ -d "$this_backup_path" ];then
        stop "$container_name"        
        rsync -avz ${this_backup_path}/ ${server_path} --delete 
        start "$container_name"
    fi
}

while [ ! -z "$1" ]; do
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]];then
        show_usage
    elif [[ "$1" == "--init" ]] || [[ "$1" == "-i" ]];then
        init $2
        shift 2
    elif [[ "$1" == "--create" ]];then
        create
        shift
    elif [[ "$1" == "--start" ]];then
        start
        shift
    elif [[ "$1" == "--stop" ]];then
        stop
        shift
    elif [[ "$1" == "--backup" ]];then
        backup_data
        shift
    elif [[ "$1" == "--restore" ]];then
        restore_data
        shift
    else
        echo "Incorrect input provided"
        show_usage
    fi
shift
done
