#!/bin/bash

#EPGDB更新を行う。

#EPGDB更新プログラムのディレクトリ(更新プログラムの設定ファイルはここに置く)
DBUpdaterDir=${HOME}/EPGUpdater

#EPGDB更新プログラム(jar)のパス
DBUpdater=${DBUpdaterDir}/EPGUpdater.jar

pdir=${HOME}
#echo ${pdir}

#EPG XMLファイル保存先ディレクトリ
epgdir=${pdir}/epg_xml

#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
_lockfile="/tmp/`basename $0`.lock"
ln -s /dummy $_lockfile 2> /dev/null || { echo 'Cannot run multiple instance.' >&2; exit 9; }
trap "rm $_lockfile; exit" 1 2 3 15

java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir}

rm $_lockfile