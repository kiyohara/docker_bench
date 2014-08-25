#!/bin/bash

######################################################################

BIN_PATH=$(cd `dirname $0`; pwd)
TEST_DIR_BASE=tests
DEFAULT_VAR_FILE=default_vars.sh
FORCE_VAR_FILE=force_vars.sh
OUT_DIR_BASE=out
OUT_DIR_LAST=last

OUT_LOG_FILE=result.log
OUT_DB_FILE=result.sqlite3
OUT_CSV_FILE=result.csv

OUT_GRAPH=(
  time_docker_run:sec
  mem_free:byte
  mem_used_all_delta:byte
  mem_used_container_ave:byte
)
OUT_GRAPH_SIZE="1920,1080"

OUT_PATH_BASE=$BIN_PATH/../$OUT_DIR_BASE
[ -d $OUT_PATH_BASE ] || mkdir -p $OUT_PATH_BASE
OUT_PATH_BASE=$(cd $OUT_PATH_BASE; pwd)

######################################################################

echo ======================================================================
echo "-->> test prepare start `date`"
echo ======================================================================

if [ -d "$1" ];then
  SUB_TEST_DIRS=$1
elif [ -d "./$TEST_DIR_BASE" ];then
  SUB_TEST_DIRS=`find ./$TEST_DIR_BASE/* -maxdepth 1 -type d`
  DEFAULT_VAR_PATH=`find ./$TEST_DIR_BASE/$DEFAULT_VAR_FILE -maxdepth 1 2>/dev/null`
  FORCE_VAR_PATH=`find ./$TEST_DIR_BASE/$FORCE_VAR_FILE -maxdepth 1 2>/dev/null`
else
  echo "Error: `pwd`/$TEST_DIR_BASE/<sub_test_dir>/vars.sh required"
  exit 1
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
if [ ! $SKIP_DOCKER_BUILD ]; then
  $BIN_PATH/build_container.sh
fi
########## create docker container --<

echo ======================================================================
echo "<<-- test prepare finish `date`"
echo ======================================================================

for _sub_test_dir in $SUB_TEST_DIRS;do

  echo ======================================================================
  echo "-->> test $_sub_test_dir start `date`"
  echo ======================================================================

  _out_dir_sub_test=$OUT_PATH_BASE/$OUT_DIR_TEST_SET/`basename $_sub_test_dir`
  _out_log_path=$_out_dir_sub_test/$OUT_LOG_FILE
  _out_db_path=$_out_dir_sub_test/$OUT_DB_FILE
  _out_cvs_path=$_out_dir_sub_test/$OUT_CSV_FILE

  # pre process
  mkdir -p $_out_dir_sub_test
  $BIN_PATH/clean_rm.sh
  $BIN_PATH/restart_docker.sh

  # bench
  $BIN_PATH/bench.sh $DEFAULT_VAR_PATH $_sub_test_dir $FORCE_VAR_PATH \
    | tee $_out_log_path
  [ ${PIPESTATUS[0]} -gt 0 ] && exit 1

  # post process
  $BIN_PATH/clean_rm.sh

  # parse output & analyze
  echo
  echo "convert $OUT_LOG_FILE to $OUT_DB_FILE"
  $BIN_PATH/log2sqlite.rb -l $_out_log_path -d $_out_db_path

  echo "analyze $OUT_DB_FILE -> $OUT_CSV_FILE"
  $BIN_PATH/analyze.rb -d $_out_db_path > $_out_cvs_path

  for i in ${OUT_GRAPH[@]};do
    _filter_name=`echo $i | cut -d':' -f 1`
    _ylabel=`echo $i | cut -d':' -f 2`

    _out_csv_path=${_out_cvs_path%.csv}__$_filter_name.csv
    echo "analyze $OUT_DB_FILE -($_filter_name)-> `basename $_out_csv_path`"
    $BIN_PATH/analyze.rb \
      --filter "container_num,$_filter_name" \
      -d $_out_db_path > $_out_csv_path

    _out_plot_dat_path=${_out_csv_path%.csv}_plot.dat
    $BIN_PATH/analyze.rb \
      --filter "container_num,$_filter_name" \
      --separator " " \
      --no-header \
      -d $_out_db_path > $_out_plot_dat_path

    _out_png_path=${_out_plot_dat_path%.dat}.png
    gnuplot -e " \
      set terminal png size $OUT_GRAPH_SIZE; \
      set out '$_out_png_path'; \
      set xlabel '# of container'; \
      set ylabel '$_ylabel'; \
      plot '$_out_plot_dat_path' title '$_filter_name'; \
    "
  done

  echo ======================================================================
  echo "<<-- test $_sub_test_dir finish `date`"
  echo ======================================================================
done

echo ======================================================================
echo "-->> ALL test compare start `date`"
echo ======================================================================

pushd $OUT_PATH_BASE/$OUT_DIR_TEST_SET >/dev/null

for i in ${OUT_GRAPH[@]};do
  _filter_name=`echo $i | cut -d':' -f 1`
  _ylabel=`echo $i | cut -d':' -f 2`

  _plot_params=''
  for _sub_test_dir in $SUB_TEST_DIRS;do
    _out_dir_sub_test=$OUT_PATH_BASE/$OUT_DIR_TEST_SET/`basename $_sub_test_dir`
    _plot_dat_path="$_out_dir_sub_test/${OUT_CSV_FILE%.csv}__${_filter_name}_plot.dat"
    _plot_param="'$_plot_dat_path' title '`basename $_sub_test_dir`'"

    if [ -n "$_plot_params" ];then
      _plot_params="$_plot_params,$_plot_param"
    else
      _plot_params="$_plot_param"
    fi
  done

  _out_png_path=${_filter_name}.png

  gnuplot -e " \
    set terminal png size $OUT_GRAPH_SIZE; \
    set out '$_out_png_path'; \
    set xlabel '# of container'; \
    set ylabel '$_ylabel'; \
    plot $_plot_params; \
  "
done

popd >/dev/null

echo ======================================================================
echo "-->> ALL test compare finish `date`"
echo ======================================================================
