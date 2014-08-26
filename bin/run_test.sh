#!/bin/bash

######################################################################

BIN_PATH=$(cd `dirname $0`; pwd)
source $BIN_PATH/lib/util.sh

######################################################################

GRAPH_SETTINGS=(
  time_docker_run::sec
  mem_free::byte
  mem_used_all_delta::byte
  mem_used_container_ave::byte
)

######################################################################

echo ======================================================================
echo "-->> test prepare start `date`"
echo ======================================================================

if [ -d "$1" ];then
  SUB_TEST_DIRS=$1
elif [ -d "./$TEST_SET_DIR_NAME" ];then
  SUB_TEST_DIRS=`_find_dir ./$TEST_SET_DIR_NAME`
  DEFAULT_VAR_PATH=`_find_file ./$TEST_SET_DIR_NAME/$DEFAULT_VAR_FILE_NAME`
  FORCE_VAR_PATH=`_find_file ./$TEST_SET_DIR_NAME/$FORCE_VAR_FILE_NAME`
else
  echo "Error: `pwd`/$TEST_SET_DIR_NAME/<sub_test_dir>/$VAR_FILE_NAME required"
  exit 1
fi

########## create test set dir -->
RESULT_DIR_PATH=$BIN_PATH/../$RESULT_DIR_NAME/`_date`
[ -d $RESULT_DIR_PATH ] || mkdir -p $RESULT_DIR_PATH
RESULT_DIR_PATH=$(cd $RESULT_DIR_PATH; pwd)

pushd `dirname $RESULT_DIR_PATH` >/dev/null

# create 'last' symlink
if [ -s $RESULT_DIR_SHORTCUT_NAME ];then
  rm $RESULT_DIR_SHORTCUT_NAME
fi
ln -s `basename $RESULT_DIR_PATH` $RESULT_DIR_SHORTCUT_NAME

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

  _out_dir_sub_test=$RESULT_DIR_PATH/`basename $_sub_test_dir`
  _out_log_path=$_out_dir_sub_test/$RESULT_LOG_FILE_NAME
  _out_db_path=$_out_dir_sub_test/$RESULT_DB_FILE_NAME
  _out_cvs_path=$_out_dir_sub_test/$RESULT_CSV_FILE_NAME

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
  echo "convert $RESULT_LOG_FILE_NAME to $RESULT_DB_FILE_NAME"
  $BIN_PATH/log2sqlite.rb -l $_out_log_path -d $_out_db_path

  echo "analyze $RESULT_DB_FILE_NAME -> $RESULT_CSV_FILE_NAME"
  $BIN_PATH/analyze.rb -d $_out_db_path > $_out_cvs_path

  for i in ${GRAPH_SETTINGS[@]};do
    _filter_name=`echo $i | cut -d':' -f 1`
    _graph_title=`echo $i | cut -d':' -f 2`
    _ylabel=`echo $i | cut -d':' -f 3`

    _out_csv_path=${_out_cvs_path%.csv}__$_filter_name.csv
    echo "analyze $RESULT_DB_FILE_NAME -($_filter_name)-> `basename $_out_csv_path`"
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
    _graph_title=${_graph_title:-$_filter_name}
    gnuplot -e " \
      set terminal png size $RESULT_GRAPH_SIZE; \
      set out '$_out_png_path'; \
      set title '$_graph_title'; \
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

for i in ${GRAPH_SETTINGS[@]};do
  _filter_name=`echo $i | cut -d':' -f 1`
  _graph_title=`echo $i | cut -d':' -f 2`
  _ylabel=`echo $i | cut -d':' -f 3`

  _plot_params=''
  for _sub_test_dir in $SUB_TEST_DIRS;do
    _load_vars $_sub_test_dir/$VAR_FILE_NAME
    _test_title=${TEST_DESCRIPTION:-`basename $_sub_test_dir`}

    _out_dir_sub_test=$RESULT_DIR_PATH/`basename $_sub_test_dir`
    _plot_dat_path="$_out_dir_sub_test/${RESULT_FILE_BASENAME}__${_filter_name}_plot.dat"
    _plot_param="'$_plot_dat_path' title '$_test_title'"

    if [ -n "$_plot_params" ];then
      _plot_params="$_plot_params,$_plot_param"
    else
      _plot_params="$_plot_param"
    fi
  done

  _out_png_path=${_filter_name}.png
  _graph_title=${_graph_title:-$_filter_name}

  pushd $RESULT_DIR_PATH >/dev/null

  gnuplot -e " \
    set terminal png size $RESULT_GRAPH_SIZE; \
    set out '$_out_png_path'; \
    set title '$_graph_title'; \
    set xlabel '# of container'; \
    set ylabel '$_ylabel'; \
    plot $_plot_params; \
  "

  popd >/dev/null
done

echo ======================================================================
echo "-->> ALL test compare finish `date`"
echo ======================================================================
