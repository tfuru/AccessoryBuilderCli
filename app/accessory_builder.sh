#!/bin/bash

# 実行例
# ./accessory_builder.sh umbrella-accessory.zip Umbrella_Sample_B.png ./textures/Umbrella_Sample_A.png "開いた傘(青)"
# ./accessory_builder.sh umbrella-accessory.zip Umbrella_Sample_B.png ./textures/Umbrella_Sample_B.png "開いた傘(赤)"
# ./accessory_builder.sh umbrella-accessory.zip Umbrella_Sample_B.png ./textures/Umbrella_Sample_C.png "開いた傘(黄)"

# ./accessory_builder.sh kimoneze-accessory.zip deva01.png ./textures/deva01_A.png "きもねーぜA"
# ./accessory_builder.sh kimoneze-accessory.zip deva01.png ./textures/deva01_B.png "きもねーぜB"
# ./accessory_builder.sh kimoneze-accessory.zip deva01.png ./textures/deva01_C.png "きもねーぜC"
# ./accessory_builder.sh kimoneze-accessory.zip deva01.png ./textures/deva01_D.png "きもねーぜD"

cat <<__EOT__
templateName $1
imageName $2
filePath $3
name $4

__EOT__

if [ $# -ne 4 ]; then
  echo "parameters are required for execution" 1>&2
  echo "./accessory_builder.sh <templateName> <imageName> <filePath> <name>"
  exit 1
fi

# 環境変数を読み込む
source .env

# テンプレート glb を展開する
unzip -l ./accessory-template/$1
unzip -o ./accessory-template/$1 -d ./tmp/

# npm i -g gltf-pipeline
gltf-pipeline -i ./tmp/accessory_template.glb -o ./tmp/output.gltf -t
rm ./tmp/accessory_template.glb

# ./tmp/accessory_template.glb 内のテクスチャを差し替える
cp $3 ./tmp/$2
gltf-pipeline -i ./tmp/output.gltf -o ./tmp/output.gltf

# TODO アイテム名を編集する
# cat ./tmp/output.gltf | jq -r '.extensions.ClusterItem.item' > ./tmp/ClusterItem-item.txt
# cat ./tmp/ClusterItem-item.txt | base64 -d -i > ./tmp/ClusterItem-item.hex
# hexdump -C tmp/ClusterItem-item.hex
# rm ./tmp/ClusterItem-item.txt ./tmp/ClusterItem-item.bin

# サムネイル画像を生成する
# npm i -g @shopify/screenshot-glb
export PUPPETEER_EXECUTABLE_PATH=`which chromium`
screenshot-glb -i ./tmp/output.gltf -o ./tmp/icon.png --width 1024 --height 1024

# accessory_template.glb を再作成する
gltf-pipeline -i ./tmp/output.gltf -o ./tmp/accessory_template.glb

# 不要なファイルを削除する
rm ./tmp/output.gltf
rm ./tmp/$2
rm ./tmp/accessory_file.zip

# accessory_template.glb と icon.png を zip 圧縮して ファイル名を accessory_file.zip にする
zip -j -r ./tmp/accessory_file.zip ./tmp/*

# 圧縮した zip ファイルを確認する
unzip -l ./tmp/accessory_file.zip

# 不要なファイルを削除する
rm ./tmp/accessory_template.glb
rm ./tmp/icon.png

# payload.json を作成する
# JSON accessoryTemplateId, ContentType, FileName, binary.Length
fileSize=$(stat -f "%z" ./tmp/accessory_file.zip)
payload='{"accessoryTemplateId":0,"ContentType":"application/zip","FileName":"accessory_file.zip","FileSize":'$fileSize'}'
echo $payload > ./tmp/payload.json

API_URL="https://api.cluster.mu/v1/upload/accessory_template/policies"

# headers.txt を 生成する
sed "s/{ClusterAccessToken}/$ClusterAccessToken/g" ./system/headers.template > ./tmp/headers.txt

# 圧縮したzpファイルをアップロードする ヘッダーは headers.txt に記載
result=$(curl -X POST -H @./tmp/headers.txt -d @./tmp/payload.json $API_URL)

# 不要ファイルを削除する
rm ./tmp/headers.txt
rm ./tmp/payload.json

accessoryTemplateID=$(echo $result | jq -r '.accessoryTemplateID')
forms=$(echo $result | jq -r '.form')
uploadUrl=$(echo $result | jq -r '.uploadUrl')
key=$(echo $forms | jq -r '.key')

# forms を forms.txt として出力
# query=$(echo $forms | jq -r 'to_entries[] | "\(.key)=\(.value)"' | tr '\n' '&')
query=$(echo $forms | jq -r 'to_entries[] | "\(.key)=\(.value)"')

# アップロード成功を監視する場合 statusApiUrl を使用する
statusApiUrl=$(echo $result | jq -r '.statusApiUrl')

FILE_NAME="./tmp/upload.sh"
echo "#!/bin/bash" > $FILE_NAME
echo "" >> $FILE_NAME
echo "curl -X POST \\" >> $FILE_NAME
# query を一行づつ出力
for q in $query; do
  echo "-F \"${q}\" \\" >> $FILE_NAME
done

echo "-F file=@./tmp/accessory_file.zip \\" >> $FILE_NAME
echo "$uploadUrl" >> $FILE_NAME

chmod +x $FILE_NAME
./$FILE_NAME

# 不要ファイルを削除する
rm $FILE_NAME
rm ./tmp/accessory_file.zip

# アップロード後のエラー内容を確認する
echo "statusApiUrl $statusApiUrl"
curl -X GET $statusApiUrl