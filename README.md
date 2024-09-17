# WordPress構築手順書

## 事前準備

パッケージの更新
```
$ sudo apt update -y && sudo apt upgrade -y
```
### mentaユーザー作成
```
$ sudo adduser menta
info: Adding user `menta' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `menta' (1001) ...
info: Adding new user `menta' (1001) with group `menta (1001)' ...
info: Creating home directory `/home/menta' ...
info: Copying files from `/etc/skel' ...
New password:                            #設定したいパスワードを入力
Retype new password:                     #パスワードを再度入力
passwd: password updated successfully
Changing the user information for menta
Enter the new value, or press ENTER for the default
	Full Name []:                    #デフォルトの場合はEnter
	Room Number []:                  #デフォルトの場合はEnter
	Work Phone []:                   #デフォルトの場合はEnter
	Home Phone []:                   #デフォルトの場合はEnter
	Other []:                        #デフォルトの場合はEnter
Is the information correct? [Y/n] Y      #正しい場合はY
info: Adding new user `menta' to supplemental / extra groups `users' ...
info: Adding user `menta' to group `users' ...
```

作成できたか確認
```
$ cat /etc/passwd | grep menta
menta:x:1001:1001:,,,:/home/menta:/bin/bash
```
### ssh認証設定

クライアント端末にてssh鍵の作成
```
$ cd ~/.ssh
$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/ユーザー名/.ssh/id_rsa):ubuntu-dev01　　　      #ubuntu-dev01などと入力
Enter passphrase (empty for no passphrase):                                              #パスフレーズを設定する場合は入力する
Enter same passphrase again:　　　　　　　　　                                              #同じパスフレーズを再度入力する
```
> [!WARNING]
> `Enter file in which to save the key (/Users/ユーザー名/.ssh/id_rsa):`
> この部分で、そのままEnterを入力すると()内をファイル名として鍵ペアが作成される。
> 以前に同じくデフォルトの名前で作成した鍵ペアが存在する場合、上書きされる可能性があるので注意。


ssh鍵をリモート接続側(仮想マシン)に登録
```
$ cat ~/.ssh/ubuntu-dev01.pub        # 出力された文字列(公開鍵)をコピー
ssh-rsa ...
$ multipass shell ubunutu-dev01      # 仮想マシンに接続
$ su menta                           # mentaユーザーに切り替え
$ ls -al ~                           # ~/.sshが存在するか確認。
$ mkdir ~/.ssh                       # ~/.sshがなければ作成
$ vim ~/.ssh/authorized_keys         # authorized_keysファイルを作成し、先ほどコピーした文字列(公開鍵)を貼り付け
$ ls -al ~ | grep ssh                # ~/.sshの権限を確認
drwxrwxr-x 2 menta menta 4096 Sep 14 14:22 .ssh
$ chmod 700 ~/.ssh                   # ~/.sshの権限を700に設定
$ ls -l ~/.ssh                       # authorized_keysの権限を確認
-rw-rw-r-- 1 menta menta 756 Sep 14 14:19 .ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys   # authorized_keysの権限を600に設定
```

mentaユーザーでssh接続
```
$ ssh -i ~/.ssh/ubuntu-dev01 menta@[接続先のIPアドレス]
```
接続先のIPアドレスは、`ip address show`などで確認。

### Nginxのバーチャルホストの設定

バーチャルホストの設定は直接/etc/nginx/nginx.confに書くのではなく、  
includeされている/etc/nginx/conf.dの配下に拡張子をconfとして作成していく。
```
$ cat /etc/nginx/nginx.conf | grep include
    include       /etc/nginx/mime.types;
    include /etc/nginx/conf.d/*.conf;
```

バーチャルホストdev.menta.me用設定ファイルの作成
```
$ sudo vim /etc/nginx/conf.d/dev.menta.me.conf
$ cat /etc/nginx/conf.d/dev.menta.me.conf
server {
    listen 80;
    server_name dev.menta.me;        #バーチャルホスト

    root /var/www/dev.menta.me;      #ドキュメントルート
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

クライアント端末にてdev.menta.meの名前解決用設定
```
$ sudo vim /etc/hosts     # [接続先のIPアドレス] dev.menta.meを追記
$ cat /etc/hosts | grep dev.menta.me
[接続先のIPアドレス] dev.menta.me
```

### Nginxのログフォーマットの変更

/etc/nginx/nginx.confの`log_format main`の次に`log_format custom`として追記。  
`access_log  /var/log/nginx/access.log  main;` のmainをcustomに変更。
```
$ sudo vim /etc/nginx/nginx.conf

    log_format custom '$time_iso8601 '
                      'server_addr:$server_addr '
                      'host:$host '
                      'method:$request_method '
                      'reqsize:$request_length '
                      'uri:$uri '
                      'query:$query_string '
                      'status:$status '
                      'size:$body_bytes_sent '
                      'referer:$http_referer '
                      'ua:$http_user_agent '
                      'forwardedfor:$http_x_forwarded_for '
                      'reqtime:$request_time '
                      'apptime:$upstream_response_time';


    access_log  /var/log/nginx/access.log  custom;
```

ログの確認。
```
$ cat /var/log/nginx/access.log
[nginx] time:2024-09-14T20:57:28+09:00 server_addr:192.168.64.10   host:192.168.64.1     method:GET reqsize:542     uri:/?p=2802    query:p=2802    status:304      size:0  referer:-       ua:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36       forwardedfor:-    reqtime:0.000   apptime:-
```
課題のフォーマットに沿っているか確かめる。
```
[nginx] time:2023-08-06T22:21:55+09:00  server_addr:10.15.0.5   host:216.244.66.233     method:GETreqsize:217     uri:/?p=2802    query:p=2802    status:301      size:5  referer:-       ua:Mozilla/5.0 (compatible; DotBot/1.2; +https://opensiteexplorer.org/dotbot; help@moz.com)       forwardedfor:-    reqtime:0.190   apptime:0.188
```


## WordPressのインストール

### 初期設定

## php-fpm8.3のインストール

### 初期設定

## MySQL8のインストール

### 初期設定

## MySQLバックアップシェルスクリプトの作成(第5世代/5日分)
