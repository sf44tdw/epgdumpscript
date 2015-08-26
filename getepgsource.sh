#!/bin/bash

USERINFO=~/.bashrc
source ${USERINFO}

#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)

#EPGDB更新プログラムのディレクトリ(更新プログラムの設定ファイルはここに置く)
DBUpdaterDir=${HOME}/EPGUpdater
#EPGDB更新プログラム(jar)のパス
DBUpdater=${DBUpdaterDir}/EPGUpdater.jar


#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`


#このスクリプトが実行されているディレクトリ(ここと同じ場所にxmltv.dtdを置く必要がある)
#データ用ディレクトリの親ディレクトリ
pdir=${PWD}
#echo ${pdir}


#tsファイル保存先ディレクトリ
tsdir=${pdir}/ts
if [ ! -e ${tsdir} ]; then
`mkdir ${tsdir}`
fi

#EPG XMLファイル保存先ディレクトリ
epgdir=${pdir}/epg_xml
if [ ! -e ${epgdir} ]; then
`mkdir ${epgdir}`
fi

#スクリプトのログディレクトリ
LogDir=${HOME}/Log
if [ ! -e ${LogDir} ]; then
`mkdir ${LogDir}`
fi


#日付取得
Date=`date "+%Y%m%d%H%M%S"`
#ファイル名生成
FileName="D"${Date}"P"$$
LogFile=${LogDir}"/"${FileName}".log"

#放送局種別
btype=0

echo ${LogFile} > ${LogFile}

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
_pname=`basename $0`
[ $$ != `pgrep -fo $_pname` ] && { echo "既に実行中のため、終了します。" >>${LOGFILE}; exit 9; }

# ファイル更新日時が10日を越えたログファイルを削除
PARAM_DATE_NUM=10
find ${LogDir} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;

#前回のファイルが残っているかも知れないので、念のため削除
rm -f ${tsdir}/*.ts >> ${LogFile}  2>&1
rm -f ${epgdir}/*.xml >> ${LogFile}  2>&1


#in以降にチャンネル番号をスペースで区切って記入する。
for channel in 21 22 23 24 25 26 27 28 101
#for channel in 21 22

do

echo ${channel} >> ${LogFile}

/usr/local/bin/recpt1 --strip --b25 ${channel} 90 ${tsdir}/${channel}.ts 1>>${LogFile} 2>&1

case ${channel} in

#BS放送
 101 )
 btype="BS";;

#地上波
 *   )
 btype=${channel};;

esac

#echo ${btype}
/usr/local/bin/epgdump ${btype} ${tsdir}/${channel}.ts ${epgdir}/${channel}.xml

done

rm -f ${tsdir}/*.ts


java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir} 1>>${LogFile} 2>&1

#更新プログラムを待たずに消しそうなのでコメントアウト
#rm -f ${epgdir}/*.xml


