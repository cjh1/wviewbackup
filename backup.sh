#!/bin/bash
DBS="hi.db test2.db"
WVIEW_HOME=/home/cjh/wview
WVIEW_TMP=$WVIEW_HOME/tmp
DB_BACKUP=${WVIEW_HOME}/backup
DB_HOME=/home/cjh/wview
DATE=`date +%Y-%m-%d`
DEST_DIR=${DB_BACKUP}/${DATE}
#mkdir -p ${DEST_DIR}

#for DB in ${DBS}
#do
#  for TABLE in `sqlite3 ${DB} ".tables"`
#  do
#    sqlite3 ${DB} ".dump" > ${DEST_DIR}/${DB}.dump
#  done
#done
  
#cd ${DB_BACKUP}
#tar zfc $WVIEW_TMP/wview-${DATE}.tar.gz ${DATE}

function last_select_date()
{
  local last=`ls -1 $WVIEW_HOME/backup | sort | tail -1`
  echo $last
}

function select_file_timestamp()
{
  local file=$1
  local count=`wc -l $file`

  local datestamp=0
  if [[ ! $count == 0* ]]
  then 
    datestamp=`tail -1 $file | awk 'BEGIN {FS=","} {print $1}'`
  fi
  echo $datestamp
}

function select_to_file()
{
  local db=$1
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

  sqlite3  -csv -header $db "$sql" > $output_file
}

function select_table()
{
  local db=$1
  local table=$2
  local schema=`sqlite3 $db ".schema $table"`
  local last_select_datetime=0

  if [[ $schema == *dateTime* ]]
  then
    local last_select_date=`last_select_date`
    local last_select_file=$WVIEW_HOME/backup/$last_select_date/$db/$table.dump

    local last_select_datetime=0
    if [ -f $last_select_file ];
    then
      last_select_datetime=`select_file_timestamp $last_select_file`      
    fi
  fi 
  
  select_to_file $db $table $last_select_datetime
}

function select_db()
{
  local db=$1
  
  for table in `sqlite3 ${db} ".tables"`
  do
    select_table $db $table  
  done
}

for db in $DBS
do
  select_db $db
done

cd $DB_BACKUP
tar zcf $WVIEW_TMP/$DATE.tar.gz $DATE
/home/cjh/wview/gsutil/gsutil cp $WVIEW_TMP/$DATE.tar.gz gs://cjh-test
