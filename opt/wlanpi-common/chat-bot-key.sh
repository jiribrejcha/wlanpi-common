#!/usr/bin/env bash

# Script to get/set wlanpi-chat-bot API key
# Author : Nigel Bowden
#
# This script is used to manipulate and report the 
# API key of the wlanpi-chat-bot feature.
#
# Return values:
#
#   Zero = success (e.g. exit 0)
#   Non-Zero = fail (e.g. exit 1) (Note: Echo failure string before exit)
#
# Logging:
#   Log faiures to syslog
#

# fail on script errors
set -e

CHAT_BOT_ROOT=/opt/wlanpi-chat-bot
CONFIG_FILE=$CHAT_BOT_ROOT/etc/config.json
VERSION=0.1.0
SCRIPT_NAME=$(echo ${0##*/})
API_KEY=$2
DEBUG=0

# just in case we need to debug this script:
debugger() {
    if [ "$DEBUG" != '0' ];then
      echo $1
    fi
}

# check if file exists
check_file_exists() {

    debugger "($SCRIPT_NAME) Checking file exists: $1"

    filename=$1

    if [ ! -e "${filename}" ] ; then
      err_str="($SCRIPT_NAME) File not found: ${filenme}"
      echo $err_string
      logger $err_string
      exit 1
    fi

    debugger "($SCRIPT_NAME) File exists."
}

# return current API key value from chat bot config file
get_key () {

    check_file_exists $CONFIG_FILE

    # target field: "bot_token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    debugger "($SCRIPT_NAME) Getting token current value..."
    api_key=$(cat $CONFIG_FILE | grep bot_token | awk -F'"' '{print $4}')
    if [ "$?" != '0' ]; then
        err_string="($SCRIPT_NAME) Error extracting chat-bot API key from $CONFIG_FILE"
        echo $err_string
        logger $err_string
        exit 1
    else
        debugger "($SCRIPT_NAME) Got token value: $api_key"
        echo $api_key
        return 0
    fi
}

# set API key value for chat bot in config file
set_key () {

    check_file_exists $CONFIG_FILE

    debugger "($SCRIPT_NAME) Setting API key in file: $CONFIG_FILE"
    
    # set the new key in the chat bot config file
     sed -i "s/\"bot_token\":\s*\".*\"\s*,/\"bot_token\": \"$API_KEY\",/" "$CONFIG_FILE"

    if [ "$?" != '0' ]; then
        err_string="($SCRIPT_NAME) Error adding chat-bot API key to $CONFIG_FILE"
        echo $err_string
        logger $err_string
        exit 1
    else
        debugger "($SCRIPT_NAME) Added token value: $API_KEY"
        return 0
    fi
}

set_interactive () {

    debugger "Setting API key via interactive prompt"

    check_file_exists $CONFIG_FILE

    echo ""
    read -p "Please enter your Telegram API key: " API_KEY
    set_key
    echo "API key set OK."
    echo ""
    echo "Please restart your WLAN Pi for this change to take effect,"
    echo "or restart the chat-bot service with the command:"
    echo ""
    echo "   systemctl restart wlanpi-chat-bot"
    echo ""

    read -p "Would you like me to restart the chat-bot service for you now? (y/n): " yn
    case $yn in
        [Yy]* ) systemctl restart wlanpi-chat-bot; echo "Restarted.";;
        * ) echo "Not restarted"; echo ""; exit 0;;
    esac

    echo ""
    read -p "Would you like to check the chat-bot process status? (y/n): " yn
    echo ""
    case $yn in
        [Yy]* ) systemctl status wlanpi-chat-bot | grep "Active:" ; echo "";;
        * ) echo "Exiting..."; echo ""; exit 0;;
    esac
    return 0

}

# return help string that provides short-form overview
# of this command
help () {
    echo "Get or set the API key for your chat-bot"
    return 0
}

# usage output
usage () {
        echo "Usage: chat-bot-key.sh {-v | get | set | help}"
        echo ""
        echo "  chat-bot-key.sh -v : show script version"
        echo "  chat-bot-key -i : set API key interactively"
        echo "  chat-bot-key.sh get: show current API key"
        echo "  chat-bot-key.sh set [api str]: set API key"
        echo "  chat-bot-key.sh : show usage info"
        echo ""
        return 0

}

debugger "--- Debug on ---"

# case statements
case "$1" in
  -v)
        echo "$VERSION"
        ;;
  -i)
        set_interactive
        ;;
  get)
        get_key
        ;;
  set)
        set_key
        ;;
  help)
        help
        ;;
  *)
        usage
        ;;
esac

exit 0
