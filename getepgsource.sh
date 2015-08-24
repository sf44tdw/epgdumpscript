#!/bin/bash
#EPG取得のため、地上波物理チャンネル全てと、BSチャンネルから1つを選択し、90秒間録画する。
#BSch=101(NHK BS1)

#EPGDB更新プログラム(jar)のパス
DBUpdater="~/EPGUpdater/EPGUpdater.jar"

#ワークディレクトリをこのスクリプトが置かれている場所にする。
cd `dirname $0`

#このスクリプトが実行されているディレクトリ(ここと同じ場所にxmltv.dtdを置く必要がある)
edir=`dirname $0`

#データ用ディレクトリの親ディレクトリ
pdir={edir}
#pdir=$(cd $(dirname $0)/..;pwd)

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

#放送局種別
btype=0

#前回のファイルが残っているかも知れないので、念のため削除
rm -f ${tsdir}/*.ts
rm -f ${epgdir}/*.xml

#in以降にチャンネル番号をスペースで区切って記入する。
for channel in 21 22 23 24 25 26 27 28 101

do

echo ${channel}

/usr/local/bin/recpt1 --strip --b25 ${channel} 90 ${tsdir}/${channel}.ts

case ${channel} in

#BS放送
 101 )
 btype="BS";;

#地上波
 *   )
 btype=${channel};;

esac

echo ${btype}
epgdump ${btype} ${tsdir}/${channel}.ts ${epgdir}/${channel}.xml

done

rm -f ${tsdir}/*.ts


java -jar ${DBUpdater} "UTF-8" ${epgdir}


rm -f ${epgdir}/*.xml
