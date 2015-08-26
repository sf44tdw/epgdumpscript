#!/bin/bash

#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)

#スクリプトのログディレクトリ
LogDir=${HOME}/Log

LogDir_epgDump=${LogDir_P}/epgDumpLog
if [ ! -e ${LogDir} ]; then
`mkdir ${LogDir}`
fi

LogDir_epgDump=${LogDir_P}/epgDumpLog
if [ ! -e ${LogDir_epgDump} ]; then
`mkdir ${LogDir_epgDump}`
fi

#日付取得
Date=`date "+%Y%m%d%H%M%S"`
#ファイル名生成
FileName="D"${Date}"P"$$
LogFile=${LogDir_epgDump}"/"${FileName}".log"

echo ${LogFile} > ${LogFile}

echo "*******************************************************************************" >> ${LogDir_epgDump}
echo "TIME" >> ${LogDir_epgDump}

#今の時間(何時?)
NowHour=`date +%k`

#割る数
Dev=4

mod=$(( ${NowHour} % ${Dev} ))

#割る数で割り切れない時間なら起動しない。
if [ ! "0" -eq ${mod} ]; then  
  echo ${NowHour} " は、" ${Dev}"で割り切れる時間ではありません。">> ${LogFile}
  exit 1
fi

echo "*******************************************************************************" >> ${LogDir_epgDump}

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
_lockfile="/tmp/`basename $0`.lock"
ln -s /dummy $_lockfile 2> /dev/null || { echo 'Cannot run multiple instance.' >> ${LogFile}; exit 9; }
trap "rm $_lockfile; exit" 1 2 3 15



# ファイル更新日時が10日を越えたログファイルを削除
PARAM_DATE_NUM=10
find ${LogDir_epgDump} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;

#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`

pdir=${HOME}


#EPG XMLファイル保存先ディレクトリ
epgdir=${pdir}/epg_xml
if [ ! -e ${epgdir} ]; then
`mkdir ${epgdir}`
fi

#前回のファイルが残っているかも知れないので、念のため削除
rm -f ${tsdir}/*.ts
rm -f ${epgdir}/*.xml

#放送局種別
btype=0

#in以降にチャンネル番号をスペースで区切って記入する。
for channel in 21 22 23 24 25 26 27 28 101
#for channel in 21 22

do
echo "*******************************************************************************" >> ${LogDir_epgDump}
echo ${channel} >> ${LogDir_epgDump}

/usr/local/bin/recpt1 --strip --b25 ${channel} 90 ${tsdir}/${channel}.ts 1>>${LogDir_epgDump} 2>&1

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
echo "*******************************************************************************" >> ${LogDir_epgDump}
done

rm -f ${tsdir}/*.ts

LogDir_UpdateDB=${LogDir_P}/epgDumpLog/epgUpdaterLog
if [ ! -e ${LogDir_UpdateDB} ]; then
`mkdir ${LogDir_epgDump}`
fi

#EPGDB更新を行う。

#EPGDB更新プログラムとDTDファイルのディレクトリ(更新プログラムの設定ファイルはここに置く)
DBUpdaterDir=${HOME}/EPGUpdater

#EPGDB更新プログラム(jar)のパス
DBUpdater=${DBUpdaterDir}/EPGUpdater.jar

#EPG XMLファイル保存先ディレクトリ
epgdir=${pdir}/epg_xml

java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir}

rm -f ${epgdir}/*.xml


rm $_lockfile
