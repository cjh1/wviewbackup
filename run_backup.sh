CONFIG_FILE="email.conf"
if [[ -O $CONFIG_FILE ]]; then
    if [[ $(stat --format %a $CONFIG_FILE) == 600 ]]; then
        . $CONFIG_FILE
    else
      echo "Config file does not have the correct permissions"
      exit -1
    fi
else
  echo "No config file"
  exit -1
fi

./backup.sh &> /tmp/backup.log

if [ $? -ne 0 ]; then
	cat /tmp/backup.log | sendEmail -t $TO \
	-u "wview upload error"
	-s $SMTP_SERVER \
	-xu $USER -xp $PASSWORD
fi

