# AccessoryBuilderCli
コマンドラインからClusterのアクセサリを作成するツール

アクセサリー作成を Unity不要で Webから利用できるようにしたくて Creator Kit を解析した時にできた副産物  
Webサービス化の前の調査用に作成したものなので、不具合があるかもしれません。

# Cluster アクセストークン変更
`app/.env` ファイルの内容を自分の [cluster アクセストークン](https://cluster.mu/account/tokens) に変更する

```
cd app
vi .env
ClusterAccessToken=xxxxxx
```


# 使い方
macの環境で動作させる事ができます

```
cd app

# 必要ライブラリのインストール
chmod +x install.sh
sudo ./install.sh

# アクセサリーを登録する
chmod +x accessory_builder.sh
./accessory_builder.sh umbrella-accessory.zip Umbrella_Sample_B.png ./textures/Umbrella_Sample_A.png "開いた傘(青)"
```

