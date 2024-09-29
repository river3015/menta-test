# WordPress構築手順書

## 事前準備

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

### パッケージのインストール

パッケージの更新
```
$ sudo apt update -y && sudo apt upgrade -y
```
Ubuntuのデフォルトリポジトリでパッケージをインストールできない場合は、公式ドキュメントを参照し
インストール先リポジトリの設定に追加する。
```
$ apt list | grep nginx
$ sudo apt install nginx -y

$ apt list | grep php8.3
$ sudo apt install php8.3-fpm php8.3-mysql php8.3-xml php8.3-gd php8.3-curl php8.3-mbstring php8.3-zip -y

$ apt list | grep mysql-server
$ sudo apt install mysql-server -y
```

## Nginxの設定

### nginx.confの設定

デフォルトの設定ファイルのバックアップ
```
$ sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
```

```
$ sudo vim /etc/nginx/nginx.conf
$ sudo cat /etc/nginx/nginx.conf
user  www-data;
worker_processes  auto;
worker_rlimit_nofile 1024;

#error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format custom '[nginx] time:$time_iso8601\t'
                      'server_addr:$server_addr\t'
                      'host:$remote_addr\t'
                      'method:$request_method\t'
                      'reqsize:$request_length\t'
                      'uri:$request_uri\t'
                      'query:$query_string\t'
                      'status:$status\t'
                      'size:$body_bytes_sent\t'
                      'referer:$http_referer\t'
                      'ua:$http_user_agent\t'
                      'forwardedfor:$http_x_forwarded_for\t'
                      'reqtime:$request_time\t'
                      'apptime:$upstream_response_time';

    sendfile        on;
    tcp_nopush     on;

    keepalive_timeout  65;

    gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
```

### バーチャルホストの設定

バーチャルホストの設定は直接/etc/nginx/nginx.confに書くのではなく、  
includeされている/etc/nginx/conf.dの配下に拡張子をconfとして作成していく。

```
$ sudo vim /etc/nginx/conf.d/dev.menta.me.conf
$ cat /etc/nginx/conf.d/dev.menta.me.conf
server {
    listen       80;
    server_name  dev.menta.me;
    root         /var/www/dev.menta.me;

    index        index.php index.html index.htm;

    access_log   /var/log/nginx/dev.menta.me.access.log  custom;
    error_log    /var/log/nginx/dev.menta.me.error.log   notice;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location ~ \.php$ {
        fastcgi_pass   unix:/run/php/php8.3-fpm.sock;
        fastcgi_index  index.php;
	fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }

}
```

クライアント端末にてdev.menta.meの名前解決用設定
```
$ sudo vim /etc/hosts     # [接続先のIPアドレス] dev.menta.meを追記
$ cat /etc/hosts | grep dev.menta.me
[接続先のIPアドレス] dev.menta.me
```

テスト用のindex.htmlを作成し、ドキュメントルートに配置する。
```
$ sudo mkdir -p /var/www/dev.menta.me
$ echo '<h1>Nginx is working!</h1>' | sudo tee /var/www/dev.menta.me/index.html
$ sudo chown -R www-data:www-data /var/www/dev.menta.me
$ sudo chmod -R 755 /var/www/dev.menta.me
```

`nginx -t`で設定ファイルの書式などに問題がないか確認。
設定を変更したら都度restartやreloadを行う。
```
sudo nginx -t
sudo systemctl restart nginx
```

実際にブラウザで`http://dev.menta.me`にアクセスし、画面が表示されるか確認。


ログの確認。
```
$ cat /var/log/nginx/access.log
[nginx] time:2024-09-14T20:57:28+09:00 server_addr:192.168.64.10   host:192.168.64.1     method:GET reqsize:542     uri:/?p=2802    query:p=2802    status:304      size:0  referer:-       ua:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36       forwardedfor:-    reqtime:0.000   apptime:-
```
課題のフォーマットに沿っているか確かめる。
```
[nginx] time:2023-08-06T22:21:55+09:00  server_addr:10.15.0.5   host:216.244.66.233     method:GETreqsize:217     uri:/?p=2802    query:p=2802    status:301      size:5  referer:-       ua:Mozilla/5.0 (compatible; DotBot/1.2; +https://opensiteexplorer.org/dotbot; help@moz.com)       forwardedfor:-    reqtime:0.190   apptime:0.188
```



## php-fpm8.3の設定

### 初期設定

デフォルトの設定ファイルのバックアップ
```
$ sudo cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup
```

```
$ sudo vim /etc/php/8.3/fpm/pool.d/www.conf
$ cat /etc/php/8.3/fpm/pool.d/www.conf
[www]
user = www-data
group = www-data

listen = /run/php/php8.3-fpm.sock

listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = static

; Note: Used when pm is set to 'static', 'dynamic' or 'ondemand'
; Note: This value is mandatory.
pm.max_children = 10

; The number of requests each child process should execute before respawning.
; This can be useful to work around memory leaks in 3rd party libraries. For
; endless request processing specify '0'. Equivalent to PHP_FCGI_MAX_REQUESTS.
; Default Value: 0
pm.max_requests = 100

php_admin_value[memory_limit] = 256M
```

確認用にドキュメントルートに`info.php`を作成。
```
$ echo '<?php phpinfo(); ?>' | sudo tee /var/www/dev.menta.me/info.php
$ sudo chown -R www-data:www-data /var/www/dev.menta.me sudo chmod -R 755 /var/www/dev.menta.me
```

設定を変更したら、都度restartやreloadを行う。
```
$ sudo systemctl restart php8.3-fpm
```

実際にブラウザで`http://dev.menta.me/info.php`にアクセスし、PHPの各種情報が表示されることを確認。

## MySQL8の設定

### 初期設定

```
$ sudo mysql -u root -p
```

WordPressのデータベースやユーザーを作成。
```
mysql> CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
mysql> CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'WP4ser_StrongP@ssw0rd';
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
mysql> FLUSH PRIVILEGES;
```

実際に作成できたか確認。
```
mysql> SHOW DATABASES;
mysql> SELECT user,host FROM mysql.user;
mysql> EXIT;
```

## WordPressのインストール

### WordPressのダウンロード
```
$ cd /tmp
$ wget https://ja.wordpress.org/latest-ja.tar.gz
$ tar -xzvf latest-ja.tar.gz
```

### 初期設定

```
sudo mv /tmp/wordpress/* /var/www/dev.menta.me/
sudo chown -R www-data:www-data /var/www/dev.menta.me
sudo chmod -R 755 /var/www/dev.menta.me
```
NginxやPHP-fpmの稼働確認に使用したファイルを削除する。
```
cd /var/www/dev.menta.me
sudo rm index.html info.php
```
ブラウザで`http://dev.menta.me`にアクセスし、WordPressの画面が表示されることを確認。
MySQLで設定したデータベース名やユーザー名などを入力し、インストール
テストで記事を新規作成し、投稿できるか確認


## MySQLバックアップシェルスクリプトの作成(第5世代/5日分)

### バックアップ専用ユーザー作成

バックアップ専用ユーザのため、必要な権限のみ与える。
```
$ sudo mysql -u root -p

mysql> CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'backup_password';
mysql> GRANT SELECT, RELOAD, PROCESS,SHOW DATABASES, LOCK TABLES, EVENT, TRIGGER ON *.* TO 'backup_user'@'localhost';
mysql> FLUSH PRIVILEGES;
mysql> EXIT;
```

バックアップ格納先フォルダの作成
```
$ sudo mkdir -p /var/backups/mysql
$ sudo chown -R root:root /var/backups/mysql
```

バックアップシェルスクリプトとユーザ・パスワードは分けて管理。
```
$ sudo vim /etc/.mysql_backup.cnf
$ cat /etc/.mysql_backup.cnf
[client]
user=backup_user
password=backup_password
```

### バックアップシェルスクリプトの作成

```
$ mkdir ~/shellscripts
$ vim ~/shellscripts/mysql_backup.sh
$ cat ~/shellscripts/mysql_backup.sh
#!/bin/bash

set -eu

BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$DATE.sql"

mysqldump --defaults-extra-file=/etc/.mysql_backup.cnf --all-databases --single-transaction --skip-lock-tables --quick --default-character-set=utf8mb4 > $BACKUP_FILE

OLDDATE=$(date --date "5 days ago" +%Y%m%d)
rm -f $BACKUP_DIR/${OLDDATE}_*.sql
```

シェルスクリプトのお試し実行
```
$ chmod +x ~/shellscripts/mysql_backup.sh
$ cd ~/shellscripts
$ sudo ./mysql_backup.sh
```
/var/backups/mysqlにバックアップファイルが作成されたことを確認。
```
$ ls /var/backups/mysql
```

定期実行の設定。
```
$ crontab -e
```
`0 2 * * * /home/ubuntu/shellscripts/mysql_backup.sh`を最下行に追記。

毎日深夜2時に実行ということで設定する。

以上
