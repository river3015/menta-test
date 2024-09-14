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
	Full Name []:                          #デフォルトの場合はEnter
	Room Number []:                        #デフォルトの場合はEnter
	Work Phone []:                         #デフォルトの場合はEnter
	Home Phone []:                         #デフォルトの場合はEnter
	Other []:                              #デフォルトの場合はEnter
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

## WordPressのインストール

### 初期設定

## php-fpm8.3のインストール

### 初期設定

## MySQL8のインストール

### 初期設定

## MySQLバックアップシェルスクリプトの作成(第5世代/5日分)
