# dev_rails

![Ruby_On_Rails_Logo svg](https://user-images.githubusercontent.com/5633085/101983216-dfba9f80-3cbc-11eb-9c02-d406eaba9cd3.png)


- docker images
  - rails-nginx
    - nginx 1.27.2
  - rails-app
    - ruby:3.3.6 (puma)
    - rails:8.0.0
	- node:20 (yarn)
  - rails-db
    - mysql:8.0.27
  - rails-redis


- git clone or fork

```
mkdir -p ~/git/menta
cd ~/git/menta
git clone git@github.com:river3015/menta.git
```

- add localhost /etc/hosts

```
sudo vim /etc/hosts
127.0.0.1 dev-rails.techbull.cloud
```

- docker run

```
cd issue13-3
cp .env.example .env
cd docker/dev-micro/
docker-compose up -d
```

- app deploy

```
docker exec -it rails-app bash

rails db:migrate
```

- Access

http://dev-rails.techbull.cloud/

ToDo ここにスクリーンショットを追加

- DB login

```
docker exec -it rails-app bash
mysql -u root -h db -p
```

- redis login
```
docker exec -it rails-redis bash
redis-cli -h redis

```

## How to download Rails app

```
bundle exec rails new app
```
