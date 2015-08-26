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

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
_pname=`basename $0`
[ $$ != `pgrep -fo $_pname` ] && { echo "既に実行中のため、終了します。" >&2; exit 9; }

java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir} 1>>${LogFile} 2>&1