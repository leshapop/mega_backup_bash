#!/bin/bash

# --- MEGA BACKUP SCRIPT v1 (14.09.2023)---
# --- created by lpop ---
# --- This script made for backup MEGA important files ---

#USER CONFIG
#Path and names
from_backup_path=${1%/} #Use absolute path or name of working directory! (site_dir, /home/site/dir)
to_backup_path=${2%/} #Use absolute path or name of working directory! (site_dir, /home/site/dir)
#Number of backups to store
daily_store=6
weekly_store=4
monthly_store=3
yearly_store=1
BACKUPS=(daily weekly monthly yearly)
#Backup timings prio (Yearly->Monthly->Weekly->daily)
yearly_backup="31"
yearly_backup_month="Dec"
monthly_backup="01"
weekly_backup="Sun"
#Help message
usage="USAGE: $0 /path/to/your_files /path/to/backup_dir"
#Compress programs
zip_programm="gzip" # gzip OR bzip2 only supported!
#Logs
backup_log="backup_mega.log"
backup_err="backup_mega.err"

#Check for argument (backup dir)
if [[ -z $1 || -z $2 ]]; then
    echo "Error. Missing arguments. (/from/your_files /to/backup_dir)"
    echo $usage
    exit 1
elif [[ ! -d $1 || ! -e $1 ]]; then
    echo "Error. Your directory not set or not exist (backup from?)"
    echo $usage
    exit 1
elif [[ ! -d $2 || ! -e $2 ]]; then
    echo "Error. Backup directory not set or not exist! (backup to?)"
    echo $usage
    exit 1
fi

echo "Backuping directory: $from_backup_path"
echo "Store backups in: $to_backup_path"

#VARS (DO NOT EDIT)
dir_name=$(basename $from_backup_path)

#Date and time vars
day_of_week=$(date +%a)
day=$(date +%d)
month=$(date +%b)
year=$(date +%Y)
date_format="($day_of_week $day $month $year)"

#FUNCTIONS

#Main backup func
backup_add () {

    #Check for tar/zip programm is installed
    if ! $(command -v tar &> /dev/null); then
	echo "Sorry, but TAR does not exist."
	exit 1
    elif ! $(command -v $zip_programm &> /dev/null); then
	echo "Sorry, but $zip_programm does not exist."
	exit 1
    fi

    case $1 in
    "weekly")
    local backup_format="$1"
    echo "This is $1 backup. $date_format"
    ;;
    "monthly")
    local backup_format="$1"
    echo "This is $1 backup. $date_format"
    ;;
    "yearly")
    local backup_format="$1"
    echo "This is $1 backup. $date_format"
    ;;
    *)
    local backup_format="daily" #Daily by default
    echo "This is daily backup. $date_format"
    ;;
    esac
    
    case $zip_programm in
    "gzip")
    local zip_file="gz"
    ;;
    "bzip2")
    local zip_file="bz2"
    ;;
    esac

    local backup_name=$(date +%Y-%m-%d-%H-%M-%S)-$dir_name.tar.$zip_file
    local backup_full_path=$to_backup_path"/"$backup_format"/"$backup_name

    if [[ ! -e $to_backup_path"/"$backup_format ]]; then
	echo "Creating $backup_format directory..."
	$(mkdir $to_backup_path"/"$backup_format)
    fi

    #Main working program
    echo "Working.."
    $(tar -cf - $from_backup_path 2>>$backup_err | $zip_programm > $backup_full_path 2>>$backup_err)
    zip_status=$?

    if [[ $zip_status -ne 0 || ! -s $backup_full_path ]]; then
	echo "Error. See $backup_err for more info"
	exit 1
    fi

    echo "Job done. Backup $backup_full_path created."
}

#Clean backups func
backup_clean () {

echo "Start cleaning $to_backup_path"

for b_format in ${BACKUPS[@]}; do
    full_b_path=$to_backup_path"/"$b_format
    if [[ -e $full_b_path && -d $full_b_path ]]; then
    files_count=$(ls -p $full_b_path | grep -v / | wc -w)
    if [[ $files_count -gt $b_format"_store" ]]; then
        to_delete=$[$files_count-$b_format"_store"]
        echo "Files all: $files_count"
        echo "Files to delete: $to_delete"
	FILES=$(ls -p $full_b_path | grep -v /)
        counter=1

        for file in ${FILES[@]}; do
	    if [[ $counter -le $to_delete ]]; then
		echo "$counter in $to_delete"
		echo "Remove old backup: $file"
		$(rm -f $full_b_path"/"$file)
		counter=$[$counter+1]
	    else
		break
		echo "Clean ok"
	    fi
        done
    else
        echo "$full_b_path is clean. Skip..."
    fi

    else
    echo "$full_b_path not exist. Skip..."
    fi
done
}

#MAIN CODE

if [[ $month == $yearly_backup_month && $day == $yearly_backup ]]; then
    backup_add "yearly"
    backup_clean
elif [[ $day == $monthly_backup ]]; then
    backup_add "monthly"
    backup_clean
elif [[ $day_of_week == $weekly_backup ]]; then
    backup_add "weekly"
    backup_clean
else
    backup_add
    backup_clean
fi