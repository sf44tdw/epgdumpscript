#!/bin/bash
#EPG取得のため、地上波物理チャンネル全てと、BS/CSチャンネルから1つずつを選択し、90秒間録画する。
#BSch=101(NHK BS1) CSch=100(スカパー！プロモ100)

#カレントディレクトリ
cdir=`dirname $0`
echo ${cdir}

#tsファイル保存先
tsdir=${cdir}/ts

rm ${tsdir}/*.ts

for channel in 21 22 23 24 25 26 27 28 100 101

do

/usr/local/bin/recpt1 --strip --b25 ${channel} 90 ${tsdir}/${channel}.ts

done
