CONFIG_FILE = $1
if [[ -O $config_file ]]; then
    if [[ $(stat --format %a $CONFIG_FILE) == 600 ]]; then
        . $config_file
    else
      echo "Config file does not have the correct permissions"
      exit -1
    fi
else
  echo "No config file"
  exit -1
fi
