#!/bin/bash

#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)

#多重起動防止機講
# 同じ名前のプロセスが起動していたら起動しない。
_pname=`basename $0`
[ $$ != `pgrep -fo $_pname` ] && { echo "既に実行中のため、終了します。" >>${LOGFILE}; exit 9; }

#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`

#tsファイル保存先ディレクトリ
tsdir=${HOME}/ts
if [ ! -e ${tsdir} ]; then
`mkdir ${tsdir}`
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

echo ${channel} >> ${LogFile}

/usr/local/bin/recpt1 --strip --b25 ${channel} 90 ${tsdir}/${channel}.ts

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



