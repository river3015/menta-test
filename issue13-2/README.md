<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

# dev_laravel

- docker images
  - laravel-nginx
    - nginx 1.27.2-alpine
  - laravel-app
    - php:8.3-fpm-alpine
    - Laravel 11.32.0
  - laravel-db
    - mysql:8.0.27
  - laravel-redis
    - redis:latest

- git clone or fork

```
mkdir -p ~/git/menta
cd ~/git/menta
git clone git@github.com:river3015/menta.git
```

- add localhost /etc/hosts

```
sudo vim /etc/hosts
127.0.0.1 dev-laravel.techbull.cloud
```

- docker run

```
cd issue13-2
cp .env.example .env
cd docker/dev-micro
docker-compose up -d
```

- app deploy

```
docker exec -it laravel-app /bin/bash

composer install
php artisan key:generate
php artisan config:cache
php artisan migrate
```

- Access

http://dev-laravel.techbull.cloud

- DB login

```
docker exec -it laravel-app bash
mysql -u root -h db -p
```

- redis login

```
docker exec -it laravel-app bash
redis-cli -h redis
```

## How to download Laravel app

```
composer global require laravel/installer

laravel new app
or
composer create-project --prefer-dist laravel/laravel app
```
