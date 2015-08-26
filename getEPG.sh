#!/bin/bash

#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)


SKIP_YES="YES"
SKIP_NO="NO"

pdir=${HOME}

#ログディレクトリ
LogDir=${pdir}/Log
if [ ! -e ${LogDir} ]; then
 `mkdir ${LogDir}`
fi

#DBへの追加ログ(ログの管理はjavaのロガーで行う)
LogDir_UpdateDB=${LogDir}/epgUpdaterLog
if [ ! -e ${LogDir_UpdateDB} ]; then
 `mkdir ${LogDir_epgDump}`
fi

#EPGファイルの取得ログ
LogDir_epgDump=${LogDir}/epgDumpLog
if [ ! -e ${LogDir_epgDump} ]; then
 `mkdir ${LogDir_epgDump}`
fi

#日付取得
Date=`date "+%Y%m%d%H%M%S"`
#EPGファイルの取得ログファイル名生成
FileName="D"${Date}"P"$$
LogFile=${LogDir_epgDump}"/"${FileName}".log"

echo ${LogFile} > ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "TIME" >> ${LogFile}

#この処理を飛ばして次に行くか。
SKIP_CHECK_TIME=${SKIP_YES}

if [ ${SKIP_CHECK_TIME} = ${SKIP_NO} ]; then

 #cronが設定を無視して1分毎に大量に起動させることがあるので、独自に制限をかける。
 #今の時間(何時?)
 NowHour=`date +%k`

 #割る数
 Dev=2

 mod=$(( ${NowHour} % ${Dev} ))

 #割る数で割り切れない時間なら起動しない。
 if [ ! "0" -eq ${mod} ]; then  
   echo ${NowHour} " は、" ${Dev}"で割り切れる時間ではありません。">> ${LogFile}
   exit 1
 fi
else
    echo "時間チェックは行いませんでした。" >> ${LogFile}
fi
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "instance" >> ${LogFile}

#この処理を飛ばして次に行くか。
SKIP_CHECK_INSTANCE=${SKIP_NO}

if [ ${SKIP_CHECK_INSTANCE} = ${SKIP_NO} ]; then
 #多重起動防止機講
 # 同じ名前のプロセスが起動していたら起動しない。
 _lockfile="/tmp/`basename $0`.lock"
 ln -s /dummy $_lockfile 2> /dev/null || { echo 'Cannot run multiple instance.' >> ${LogFile}; exit 9; }
 trap "rm $_lockfile; exit" 1 2 3 15
else
    echo "多重起動チェックは行いませんでした。" >> ${LogFile}
fi
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "ファイル更新日時が10日を越えたログファイルを削除" >> ${LogFile}
PARAM_DATE_NUM=10
find ${LogDir_epgDump} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "受信" >> ${LogFile}
#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`

#tsファイル保存先ディレクトリ
tsdir=${pdir}/tsDir
if [ ! -e ${tsdir} ]; then
`mkdir ${tsdir}`
fi

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
echo "*******************************************************************************" >> ${LogFile}
echo "受信チャンネル:"${channel} >> ${LogFile}

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
echo "*******************************************************************************" >> ${LogFile}
done

rm -f ${tsdir}/*.ts
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "EPGDB更新" >> ${LogFile}

#EPGDB更新プログラムとDTDファイルのディレクトリ(更新プログラムの設定ファイルはここに置く)
DBUpdaterDir=${HOME}/EPGUpdater

#EPGDB更新プログラム(jar)のパス
DBUpdater=${DBUpdaterDir}/EPGUpdater.jar

#EPG XMLファイル保存先ディレクトリ
epgdir=${pdir}/epg_xml

java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir}

rm -f ${epgdir}/*.xml
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "instance" >> ${LogFile}
rm $_lockfile
echo "*******************************************************************************" >> ${LogFile}
