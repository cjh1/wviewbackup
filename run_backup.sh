CONFIG_FILE="email.conf"
source configure.sh $CONFIG_FILE

./backup.sh &> /tmp/backup.log

if [ $? -ne 0 ]; then
	cat /tmp/backup.log | sendEmail -t $TO \
	-u "wview upload error"
	-s $SMTP_SERVER \
	-xu $USER -xp $PASSWORD
fi
