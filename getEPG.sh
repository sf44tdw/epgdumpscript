#!/bin/bash

#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)

#ワークディレクトリをこのスクリプトが置かれている場所にする。(相対パスで同じディレクトリにあるファイルを読み込むため。)
cd `dirname $0`

#これら２つの変数はgetEPG.confから読み込む
#録画ファイル,EPGファイル,ログの保存先ディレクトリ(外部で定義)
#pdir=${HOME}
#EPGDB更新プログラムとDTDファイルのディレクトリ(更新プログラムの設定ファイルはここに置く)(外部で定義)
#DBUpdaterDir=${HOME}/EPGUpdater

echo "設定読み込み"
source getEPG.conf

#更新プログラムのパスを追加しておく。
export PATH=$PATH:${DBUpdaterDir}

#EPGDB更新プログラム(jar)のパス
DBUpdater=${DBUpdaterDir}/EPGUpdater.jar

#一部の処理を飛ばすときのフラグ変数
#SKIP_YES="YES"
#SKIP_NO="NO"

#bashの場合、mkdir -p "$deploydir"
#としないと不具合(mkdir: missing operand)が出ることがあるらしい。


echo "ログディレクトリ作成"
echo ${LogDir} >2
LogDir=${pdir}/Log
if [ ! -e ${LogDir} ]; then
 `mkdir "${LogDir}"`
fi

echo "DBへの追加ログ(ログの管理はjavaのロガーで行う)"
echo ${LogDir_UpdateDB}  >2
LogDir_UpdateDB=${LogDir}/epgUpdaterLog
if [ ! -e ${LogDir_UpdateDB} ]; then
 `mkdir "${LogDir_epgDump}"`
fi

echo "EPGファイルの取得ログ"
echo ${LogDir_epgDump}  >2
LogDir_epgDump=${LogDir}/epgDumpLog
if [ ! -e ${LogDir_epgDump} ]; then
 `mkdir "${LogDir_epgDump}"`
fi

#日付取得
Date=`date "+%Y%m%d%H%M%S"`
#EPGファイルの取得ログファイル名生成
FileName="D"${Date}"P"$$
LogFile=${LogDir_epgDump}"/"${FileName}".log"

echo ${LogFile} > ${LogFile}

 #cronが設定を無視して1分毎に大量に起動させることがあるので、独自に制限をかける。
 
 #時間チェック、分数チェックとも飛ばして次に行くか。
 #SKIP_CHECK_HOUR_AND_MINUTE=${SKIP_NO}
 
echo "*******************************************************************************" >> ${LogFile}
echo "時間チェック" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}

#この処理を飛ばして次に行くか。
#SKIP_CHECK_HOUR=${SKIP_NO}

if [ ${SKIP_CHECK_HOUR} = ${SKIP_NO} -o  ${SKIP_CHECK_HOUR_AND_MINUTE} = ${SKIP_NO} ]; then

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

 #cronが設定を無視して1分毎に大量に起動させることがあるので、独自に制限をかける。
echo "*******************************************************************************" >> ${LogFile}
echo "分数チェック" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}

 #今の時間(何分?)
 NowMin=`date +%M`
 
 #この処理を飛ばして次に行くか。
 #SKIP_CHECK_MINUTE=${SKIP_NO}
 
 if [ ${SKIP_CHECK_MINUTE} = ${SKIP_NO} -o  ${SKIP_CHECK_HOUR_AND_MINUTE} = ${SKIP_NO} ]; then
 #01～03分以外では起動しない。
  if [ ${NowMin} != "01" -o ${NowMin} != "02" -o  ${NowMin} != "03" ]; then  
   echo ${NowMin} " は、01～03分以外です。">> ${LogFile}
   exit 1
 fi
  else
    echo "分数チェックは行いませんでした。" >> ${LogFile}
fi

echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "instance" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}

#この処理を飛ばして次に行くか。
#SKIP_CHECK_INSTANCE=${SKIP_NO}

if [ ${SKIP_CHECK_INSTANCE} = ${SKIP_NO} ]; then
 # 多重起動防止機講
 # 同じ名前のプロセスが起動していたら起動しない。
 # プロセスが無いのに多重軌道に引っかかるときは、ロックファイルが残留している可能性がある。
 _lockfile="/tmp/`basename $0`.lock"
 ln -s /dummy $_lockfile 2> /dev/null || { echo 'Cannot run multiple instance.' >> ${LogFile}; exit 9; }
 trap "rm $_lockfile; exit" 1 2 3 15
else
    echo "多重起動チェックは行いませんでした。" >> ${LogFile}
fi
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "ファイル更新日時が10日を越えたログファイルを削除" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}
PARAM_DATE_NUM=10
find ${LogDir_epgDump} -name "*.log" -type f -mtime +${PARAM_DATE_NUM} -exec rm -f {} \;
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "受信" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}

#この処理を飛ばして次に行くか。
#SKIP_CHECK_RECEVE=${SKIP_NO}

if [ ${SKIP_CHECK_RECEVE} = ${SKIP_NO} ]; then

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
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}
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
echo "*******************************************************************************" >> ${LogFile}
done

rm -f ${tsdir}/*.ts
else
    echo "受信は行いませんでした。" >> ${LogFile}
fi
echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "EPGDB更新" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}

#この処理を飛ばして次に行くか。
#SKIP_CHECK_RECEVE=${SKIP_NO}

if [ ${foo} = ${var} ]; then

java -jar ${DBUpdater} ${DBUpdaterDir} "UTF-8" ${epgdir}

rm -f ${epgdir}/*.xml

else
    echo "DB更新は行いませんでした。" >> ${LogFile}
fi

echo "*******************************************************************************" >> ${LogFile}

echo "*******************************************************************************" >> ${LogFile}
echo "instance" >> ${LogFile}
echo `date "+%Y-%m-%d %H:%M:%S"`>> ${LogFile}
if [ ${SKIP_CHECK_INSTANCE} = ${SKIP_NO} ]; then
 #多重起動防止機講
 # 同じ名前のプロセスが起動していたら起動しない。
    rm  -f  $_lockfile
else
    echo "多重起動チェックは行いませんでした。" >> ${LogFile}
fi
echo "*******************************************************************************" >> ${LogFile}
