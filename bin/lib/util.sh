#!/bin/bash

DEBUG=0

VAR_FILE_NAME=vars.sh
DEFAULT_VAR_FILE_NAME=default_vars.sh
FORCE_VAR_FILE_NAME=force_vars.sh

TEST_SET_DIR_NAME=tests

RESULT_DIR_NAME=out
RESULT_DIR_SHORTCUT_NAME=last
RESULT_FILE_BASENAME=result
RESULT_LOG_FILE_NAME=${RESULT_FILE_BASENAME}.log
RESULT_DB_FILE_NAME=${RESULT_FILE_BASENAME}.sqlite3
RESULT_CSV_FILE_NAME=${RESULT_FILE_BASENAME}.csv

RESULT_GRAPH_SIZE="1920,1080"

######################################################################

_debug(){
  if [ -n "$DEBUG" -a $DEBUG -gt 0 ];then
    echo "DEBUG: $@"
  fi
}

_load_vars(){
  _debug "load vars called (pwd:`pwd`, args:$@)"

  local var_file
  if [ -f "$1" ];then
    _debug "$1 is file -> source $1"
    var_file=$1
    source $var_file
    return 0
  elif [ -d "$1" ];then
    var_file=$1/$VAR_FILE_NAME
    _debug "$1 is dir -> _load_vars $var_file"
    _load_vars $var_file
    return $?
  else
    _debug "$1 is neither file and dir -> error"
    return 1
  fi
}

_ps() {
  local pid=${1:-''}

  if [ $pid ];then
    if [ $pid -gt 0 ]; then
      ps -p $pid uw
      return 0
    else
      # echo invalid pid($pid)
      return 1
    fi
  else
    # echo pid required
    return 1
  fi
}

_date(){
  date +%Y%m%d_%H%M%S
}

_find_dir(){
  find ./$1/* -maxdepth 1 -type d 2>/dev/null
}

_find_file(){
  find ./$1 -maxdepth 1 2>/dev/null
}

######################################################################
