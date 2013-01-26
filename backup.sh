#!/bin/bash

function select_file_timestamp()
{ # walk through all select files checking if they are empty ...
  local db=$1
  local table=$2
  local file=$1
 
  local datestamp=0 
  for date in `ls -1 $WVIEW_HOME/backup | sort -r` 
  do
    local file=$DB_BACKUP/$date/$db/$table.dump
    if [ -s "$file" ]
    then
      datestamp=`tail -1 $file | awk 'BEGIN {FS=","} {print $1}'`
      break
    fi
  done
  
  echo $datestamp
}

function select_to_file()
{
  local db=$1
  local db_file=$DB_HOME/$db
  local table=$2
  local datetime=$3
  local output_dir=$DB_BACKUP/$DATE/$db
  local output_file=$output_dir/$table.dump
  
  mkdir -p $output_dir
  sql="select * from $table"
  if [[ ! $datetime == "0" ]]
  then
    sql+=" where dateTime > $datetime"
  fi
 
  sql+=";" 

  sqlite3  -csv -header $db_file "$sql" > $output_file
}

function select_table()
{
  local db=$1
  local db_file=$DB_HOME/$db
  local table=$2
  local schema=`sqlite3 $db_file ".schema $table"`
  local last_select_datetime=0

  if [[ $schema == *dateTime* ]]
  then
    local last_select_datetime=0
    if [ -f $last_select_file ];
    then
      last_select_datetime=`select_file_timestamp $db $table`      
    fi
  fi 
  
  select_to_file $db $table $last_select_datetime
}

function select_db()
{
  local db=$1
  local db_file=$DB_HOME/$db
  
  for table in `sqlite3 ${db_file} ".tables"`
  do
    select_table $db $table  
  done
}

function backup()
{
  date
  for db in $DBS
  do
    select_db $db
  done

  cd $DB_BACKUP
  tar zcf $WVIEW_TMP/$DATE.tar.gz $DATE
  $GSUTIL cp $WVIEW_TMP/$DATE.tar.gz $GS_BACKUP_DIR
}

CONFIG_FILE="backup.conf"
if [[ -O $CONFIG_FILE ]]; then
    if [[ $(stat --format %a $CONFIG_FILE) == 600 ]]; then
        . $CONFIG_FILE
    else
      echo "Config file does not have the correct permissions"
      exit 0
    fi
else
  echo "No config file"
  exit 0
fi

backup
