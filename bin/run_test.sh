#!/bin/bash

######################################################################

BIN_PATH=$(cd `dirname $0`; pwd)
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
if [ ! $SKIP_DOCKER_BUILD ]; then
  $BIN_PATH/build_container.sh
fi
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

  # pre process
  mkdir -p $OUT_DIR_SUB_TEST
  $BIN_PATH/clean_rm.sh
  $BIN_PATH/restart_docker.sh

  # bench
  $BIN_PATH/bench.sh $sub_test_dir | tee $OUT_LOG_PATH

  # post process
  $BIN_PATH/clean_rm.sh

  # parse output & analyze
  echo
  echo "convert $OUT_LOG_FILE to $OUT_DB_FILE"
  $BIN_PATH/log2sqlite.rb -l $OUT_LOG_PATH -d $OUT_DB_PATH

  echo "analyze $OUT_DB_FILE -> $OUT_CSV_FILE"
  $BIN_PATH/analyze.rb -d $OUT_DB_PATH > $OUT_CSV_PATH

  for i in ${OUT_CSV_FILTER[@]};do
    _out_csv_path=${OUT_CSV_PATH%.csv}__$i.csv
    echo "analyze $OUT_DB_FILE -($i)-> `basename $_out_csv_path`"
    $BIN_PATH/analyze.rb \
      --filter "container_num,$i" \
      -d $OUT_DB_PATH > $_out_csv_path
  done

  echo ======================================================================
  echo "<<-- test $sub_test_dir finish `date`"
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
    _plot_dat_path="$_sub_test_dir/${OUT_CSV_FILE%.csv}__${_filter_name}_plot.dat"
    _plot_param="'$_plot_dat_path' title '$_sub_test_dir'"

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
