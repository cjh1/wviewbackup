#!/bin/bash

SCRIPT=`basename $0`

function check_exit_code
{
  local exit_code=$?
  local check_line=$1
  local cmd_line_num=$((check_line-1))

  if [ $exit_code -ne 0 ]; then
    line=`sed "$((cmd_line_num))q;d" $SCRIPT | sed -e 's/^ *//g;s/ *$//g'`
    echo "Error at line $cmd_line_num: '$line' exit code: $exit_code"
    exit $exit_code
  fi
}

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
      check_exit_code $LINENO
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
  check_exit_code $LINENO

  sql="select * from $table"
  if [[ ! $datetime == "0" ]]
  then
    sql+=" where dateTime > $datetime"
  fi
 
  sql+=";" 

  sqlite3  -csv -header $db_file "$sql" > $output_file
  check_exit_code $LINENO
}

function select_table()
{
  local db=$1
  local db_file=$DB_HOME/$db
  local table=$2
  local schema=`sqlite3 $db_file ".schema $table"`
  check_exit_code $LINENO
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
  
  local tmp=`sqlite3 ${db_file} ".tables"`
  check_exit_code $LINENO
  for table in $tmp
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
  check_exit_code $LINENO
  tar zcf $WVIEW_TMP/$DATE.tar.gz $DATE
  check_exit_code $LINENO
  $GSUTIL cp $WVIEW_TMP/$DATE.tar.gz $GS_BACKUP_DIR
  check_exit_code $LINENO
}

CONFIG_FILE="backup.conf"
source configure.sh $CONFIG_FILE
backup
