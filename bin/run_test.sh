#!/bin/bash

######################################################################

BIN_PATH=$(cd `dirname $0`; pwd)
OUT_DIR_BASE=out
OUT_DIR_LAST=last

OUT_LOG_FILE=result.log
OUT_DB_FILE=result.sqlite3
OUT_CSV_FILE=result.csv

OUT_PATH_BASE=$BIN_PATH/../$OUT_DIR_BASE
[ -d $OUT_PATH_BASE ] || mkdir -p $OUT_PATH_BASE
OUT_PATH_BASE=$(cd $OUT_PATH_BASE; pwd)

######################################################################

echo ======================================================================
echo "-->> test prepare start `date`"
echo ======================================================================

if [ -d "$1" ];then
  SUB_TEST_DIRS=$1
else
  SUB_TEST_DIRS=`ls -1 -d _*`
fi

DATE=`date +%Y%m%d_%H%M%S`
OUT_DIR_TEST_SET=${DATE}

########## create test set dir -->
pushd $OUT_PATH_BASE >/dev/null

mkdir -p $OUT_DIR_TEST_SET

# create 'last' symlink
if [ -s $OUT_DIR_LAST ];then
  rm $OUT_DIR_LAST
fi
ln -s $OUT_DIR_TEST_SET $OUT_DIR_LAST

popd >/dev/null
########## create test set dir --<

########## create docker container -->
$BIN_PATH/build_container.sh
########## create docker container --<

echo ======================================================================
echo "<<-- test prepare finish `date`"
echo ======================================================================

for sub_test_dir in $SUB_TEST_DIRS;do
  echo ======================================================================
  echo "-->> test $sub_test_dir start `date`"
  echo ======================================================================

  if [ ! -e $sub_test_dir/vars.sh ];then
    echo !! $sub_test_dir/vars.sh required ... stop !!
    exit 1
  fi

  OUT_DIR_SUB_TEST=$OUT_PATH_BASE/$OUT_DIR_TEST_SET/`basename ${sub_test_dir}`
  OUT_LOG_PATH=$OUT_DIR_SUB_TEST/$OUT_LOG_FILE
  OUT_DB_PATH=$OUT_DIR_SUB_TEST/$OUT_DB_FILE
  OUT_CSV_PATH=$OUT_DIR_SUB_TEST/$OUT_CSV_FILE

  # bench pre process
  mkdir -p $OUT_DIR_SUB_TEST
  $BIN_PATH/clean_rm.sh
  $BIN_PATH/restart_docker.sh

  # do bench
  $BIN_PATH/bench.sh $sub_test_dir | tee $OUT_LOG_PATH

  # bench post process
  echo
  echo "convert $OUT_LOG_FILE to $OUT_DB_FILE"
  $BIN_PATH/log2sqlite.rb -l $OUT_LOG_PATH -d $OUT_DB_PATH

  echo "analyze $OUT_DB_FILE (-> $OUT_CSV_FILE)"
  $BIN_PATH/analyze.rb -d $OUT_DB_PATH > $OUT_CSV_PATH

  echo ======================================================================
  echo "<<-- test $sub_test_dir finish `date`"
  echo ======================================================================
done
