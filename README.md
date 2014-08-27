docker_bench
==========

### これは
* docker.io の性能特性を確認するためのプログラム
  * docker.io の性能に影響を及ぼす要因のうち、支配的なものを洗い出す
  * ひいては docker コンテナを用いたシステム設計（特にリソースプランニング）に際して考慮すべき要素を特定する
* nopass な `sudo` を要求するので個別に VM を立てて使うとよい
* 駆動中の全 docker コンテナを停止（snapshot も `docker rm` する）するので個別に VM を立てて使うとよい
* 動作確認をしているのは Ubuntu 14.04

### 計測シナリオ

* 変動させる値
  * 同時に実行する docker コンテナの数
  * 実行する docker コンテナの内容

* 計測する値
  * system が消費するメモリの量
  * `docker run` コマンドの `time` 値

### 出力

* 4種類のグラフを出力

* 各グラフ固有の要素
  1. `mem_free.png` ... y軸: システム全体の free なメモリ量
  1. `mem_used_all_delta.png` ... y軸: メモリ使用量の変化量（計測開始前の free なメモリ量 - 現在の free なメモリ用）
  1. `mem_used_container_ave.png` ... y軸: 1コンテナあたりを維持するために必要なメモリ量（メモリ使用量の変化量 / 実行中のコンテナ数）
  1. `time_docker_run.png` ... y軸: コンテナの起動にかかった時間[^1]

* 全グラフ共通の要素
  * x軸: 同時実行しているコンテナ数
  * plot種: 実行する docker コンテナの内容(4種 詳細後述)

[^1] `docker run` にかかった `time` 値であり、コンテナプロセスがサービスとして ready 状態になったタイミングを示すものではない点に注意。

ここはいずれ改善したいところ。
「ready 状態」をどのように定義するかによって計測の仕方は変わる。
コンテナプロセスに手を加え、ready になったと同時に STDOUT に何らかのキーワードを出力。
外部から `docker logs` で polling 観測するのが比較的簡単。
一方で、コンテナ数が増えた際に `docker` コマンド自体が非常に遅くなることがわかっている。
ready 検知の時間が（ `docker logs` コマンドの遅延分が加算され）実際より長く誤観測される可能性は高い。

### 出力サンプル

* `mem_free.png`
![](./result_sample/mem_free.png)

* `mem_used_all_delta.png`
![](./result_sample/mem_used_all_delta.png)

* `mem_used_container_ave.png`
![](./result_sample/mem_used_container_ave.png)

* `time_docker_run.png`
![](./result_sample/time_docker_run.png)

### 動作要件 [^2]
* nopass で sudo を実行できるテスト用ユーザー
* コマンド&ライブラリ
  * sudo
  * service
  * vmstat
  * mpstat
  * docker
  * jq
  * gnuplot
  * ruby
   * awesome_print gem
   * sqlite3 gem

[^2] Ubuntu でのインストール手順を後述しているので参照の程

### 使い方
1. テスト実行スクリプトを起動
  * `docker_bench/bin/run_test.sh`

1. 以下のファイルを確認する
  * `docker_bench/out/last/*.png`

### 詳細なログ
* `docker_bench/out/last/<sub_test_name>/`
  * `result.log` ... テスト実行時の STDOUT
  * `result.csv` ... STDOUT をパースして各値を CSV 化したもの
  * `result.sqlite3` ... STDOUT をパースして各値を SQLite3 フォーマットで DB 化したもの
  * `result__<col_name>.csv` ... `result.csv` の特定の列のみを抜き出したもの
  * `result__<col_name>_plot.dat` ... `gnuplot` 用に特定の列のみを抜き出したもの
  * `result__<col_name>_plot.png` ... `result__<col_name>_plot.dat` を図におこしたもの

### カスタマイズ
* テストは各サブテストに分割されている
* サブテストを順に実行した後、サブテスト横断のグラフを作成している

#### 各サブテストの内容をカスタマイズする場合
* テスト向けの各種変数が記載されている `docker_bench/tests/<sub_test_dir>/vars.sh` を編集する
* 各変数の意味は以下の通り
  * `CONTAINER_NAME`
    * 実行するコンテナプロセスのコンテナイメージ名
    * 必須
  * `CONTAINER_COUNT`
    * 同時実行させるコンテナプロセスの最大数
    * 後述の方法により上書きされうる
    * 任意(省略時は `100`)
  * `DOCKER_RUN_PARAMS`
    * `docker run` 時に付与するパラメータ(`-d` オプションを含めることを推奨)
    * 任意(省略時は `-d`)
  * `TEST_DESCRIPTION`
    * グラフ化したときに plot 種として表記される内容
    * 任意(省略時は `<sub_test_dir>`)
* 新しいコンテナ忌めー意を追加したい場合は `docker_bench/containers/<container_dir>/` 配下に Dockerfile を作成するとよい
  * テストの pre-process として `docker build` される
  * build されるコンテナイメージのタグは `<container_dir>` になる

#### サブテストを追加する場合
* `docker_bench/tests/` 配下に任意の名前でディレクトリを作成し `vars.sh` を配置する
  * `vars.sh` の記載方法は前述参照
  * `CONTAINER_NAME` 変数は必須なので留意すること

#### 各サブテストを個別に実行する場合
* `docker_bench/bin/run_test.sh` の引数に `<sub_test_dir>` を指定する
  * 例: `$ ./bin/run_test.sh tests/test1`

#### 同時実行させるコンテナプロセスの最大数を変更する場合
* `$FORCE_CONTAINER_COUNT` 環境変数を設定して `docker_bench/bin/run_test.sh` を実行する
  * 例: `$ env FORCE_CONTAINER_COUNT=10 ./bin/run_test.sh`

-----

### コンテナの内容
* コンテナプロセスとして4種類の内容を用意した
  1. test1
    * コンテナイメージ: `ping_local`
      * `FROM ubuntu:14.04`
      * 127.0.0.1 に `ping` を実行する
    * `docker run` 時のオプションとして `--net="none"` と追加している

  1. test2
    * コンテナイメージ: `ping_local`
      * `FROM ubuntu:14.04`
      * 127.0.0.1 に `ping` を実行する

  1. test3
    * コンテナイメージ: `ping_docker`
      * `FROM ubuntu:14.04`
      * docker host のインターフェイス(docker0: 172.17.42.1 決め打ち) に ping を実行する

  1. test4
    * コンテナイメージ: `em-httpd`
      * `FROM ubuntu:14.04`
      * `supervisor`[^3] で以下の子プロセスを並列実行する
        * `em-httpd.rb`(http POST を受け付け、内容を STDOUT に出力する ruby script）
        * `curl-ping.sh`(1秒間隔で 127.0.0.1 に `curl` を用いて http POST を送信する bash script)
        * `sshd`[^4]
    * python, ruby, bash の各スクリプトが駆動することもあり、メモリ使用量は多め
      * 当該コンテナプロセスの起動直後の VSZ/RSS は 46,184/10,096 byte 程

[^3] [supervisor](http://supervisord.org/) python 製プロセス管理ツール。
ここでは、同一コンテナ中で複数の子プロセスを駆動させるために使っている。

[^4] sshd はコンテナプロセスの動作を確認するために用意している。
ユーザー名 `docker` で `docker_bench/containers/test4/id_rsa` を用いてログインできる。
IP address は `docker inspect` を用いて調査すること。
`docker_bench/containers/test4/ssh.sh` を用いて、最後に起動したコンテナにログインできる。

### Ubuntu でのインストール手順

```
## テスト用の user を nopass で sudo 可能にする
$ sudo "${test_user_name} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${test_user_name}
$ sudo chmod 400 /etc/sudoers.d/${test_user_name}
### 必要に応じて relogin

## 必要となるソフトウェア&ライブラリをインストール
$ sudo apt-get -y install \
    sysstat \
    ruby \
    ruby-dev \
    make \
    sqlite \
    libsqlite3-dev \
    jq \
    gnuplot

$ sudo gem install bundler # オプショナル
$ sudo gem install awesome_print
$ sudo gem install sqlite3

### docker.io のインストール
$ curl -sSL https://get.docker.io/ubuntu/ | sudo sh
### テスト用 user に docker.io を操作可能にする
$ sudo usermod -a -G docker ${test_user_name}

### 本プログラムのセットアップ
$ git clone ${this_repo_url}
$ cd docker_bench
```
