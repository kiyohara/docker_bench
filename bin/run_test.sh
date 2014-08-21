#!/bin/bash

######################################################################

OUT_DIR_BASE=out
OUT_DIR_LAST=last

######################################################################

if [ -d "$1" ];then
  SUB_TEST_DIRS=$1
else
  SUB_TEST_DIRS=`ls -1 -d _*`
fi

DATE=`date +%Y%m%d_%H%M%S`
OUT_DIR_TEST_SET=${DATE}

########## create test set dir -->
pushd $OUT_DIR_BASE

mkdir -p $OUT_DIR_TEST_SET

# create 'last' symlink
if [ -s $OUT_DIR_LAST ];then
  rm $OUT_DIR_LAST
fi
ln -s $OUT_DIR_TEST_SET $OUT_DIR_LAST

popd
########## create test set dir --<

for sub_test_dir in $SUB_TEST_DIRS;do
  if [ ! -e $sub_test_dir/vars.sh ];then
    echo !! $sub_test_dir/vars.sh required ... stop !!
    exit 1
  fi

  OUT_DIR_SUB_TEST=$OUT_DIR_BASE/$OUT_DIR_TEST_SET/${sub_test_dir}
  LOG_FILE=$OUT_DIR_SUB_TEST/log.txt
  DB_FILE=$OUT_DIR_SUB_TEST/parse.sqlite3

  # bench pre process
  mkdir -p $OUT_DIR_SUB_TEST
  bin/clean_rm.sh
  bin/restart_docker.sh
  bin/build_container.sh $sub_test_dir

  # do bench
  bin/bench.sh $sub_test_dir | tee $LOG_FILE

  # bench post process
  echo convert $LOG_FILE to $DB_FILE
  bin/log2sqlite.rb -l $LOG_FILE -d $DB_FILE
done
