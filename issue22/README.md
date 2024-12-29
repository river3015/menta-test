# Wordpress By Kubernetes

## Versions
- kubectl version
```
Client Version: v1.30.5
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.30.2
```

## docker base images
- web
  - nginx:1.27.2-alpine
- app
  - php:8.3-fpm-alpine
- db
  - mysql:8.0.27

## Directory

```
(~/git/menta/issue22)$ ls -a
.          ..         .gitignore README.md  docker     k8s        wordpress

tree docker
docker
├── app
│   ├── Dockerfile
│   └── php
│       ├── php-fpm.conf
│       ├── php.ini
│       └── www.conf
├── mysql
│   ├── Dockerfile
│   ├── db_data #ommision
│   ├── my.cnf
│   └── mysql.gpg
└── nginx
    ├── Dockerfile
    └── conf
        ├── dev-k8s.techbull.cloud.conf
        └── nginx.conf

tree k8s
k8s
├── app.yaml
├── ingress.yaml
├── mysql.yaml
└── secrets.yaml
```

## Several Settings

- git clone or fork

```
mkdir -p ~/git/menta
cd ~/git/menta
git clone git@github.com:river3015/menta.git
```

- add localhost /etc/hosts

```
sudo vim /etc/hosts
127.0.0.1 dev-k8s.techbull.cloud
```

- setting wp-config.php

```
cd issue22
cp wordpress/wp-config-sample.php wordpress/wp-config.php
```

- WordPress official random key generate

https://api.wordpress.org/secret-key/1.1/salt/

copy & paste

```
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
```

## Build Docker image

- check docker context

```
(~/git/menta/issue22/docker/nginx)$ docker build . -t issue22/nginx:v1.0.0
(~/git/menta/issue22)$ docker build -t issue22/app:v1.0.0 -f docker/app/Dockerfile .
(~/git/menta/issue22/docker/mysql)$ docker build . -t issue22/mysql:v1.0.0
```

## Setting Kubernetes

- check use-context and create your namespace

```
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl create namespace dev-techbull-k8s
```

```
kubectl create namespace dev-techbull-k8s
Unable to connect to the server: dial tcp: lookup kubernetes.docker.internal: no such host
```
```
sudo vim /etc/hosts
127.0.0.1 kubernetes.docker.internal
```

- make secrets.yaml to create secret/mysql-secret

By environment variables, pass informations to containers for access databases
In secrets.yaml, such values are encoded by base64

```
echo -n "wordpress" | base64
d29yZHByZXNz
```

- secrets.yaml

DB_ : use for wp-config.php
MYSQL_ : use for mysql container

```
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  DB_NAME: (string encoded by base64)
  DB_USER: (string encoded by base64)
  DB_PASSWORD: (string encoded by base64)
  DB_HOST: (string encoded by base64)
  MYSQL_DATABASE: (string encoded by base64)
  MYSQL_USER: (string encoded by base64)
  MYSQL_PASSWORD: (string encoded by base64)
  MYSQL_ROOT_PASSWORD: (string encoded by base64)
```

- create k8s resources

create Ingress-NGINX controller
reference: https://github.com/kubernetes/ingress-nginx

I chose v1.11.3
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
```

```
(~/git/menta/issue22/k8s)$ kubectl -n dev-techbull-k8s apply -f secrets.yaml
(~/git/menta/issue22/k8s)$ kubectl -n dev-techbull-k8s apply -f ingress.yaml
(~/git/menta/issue22/k8s)$ kubectl -n dev-techbull-k8s apply -f app.yaml
(~/git/menta/issue22/k8s)$ kubectl -n dev-techbull-k8s apply -f mysql.yaml
```

## Check Resource

```
kubectl -n dev-techbull-k8s get ingress,secret,service,deployment,statefulset,pod,pvc
NAME                                  CLASS   HOSTS                    ADDRESS     PORTS   AGE
ingress.networking.k8s.io/wordpress   nginx   dev-k8s.techbull.cloud   localhost   80      19h

NAME                  TYPE     DATA   AGE
secret/mysql-secret   Opaque   8      4h46m

NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/mysql       ClusterIP   None            <none>        3306/TCP   4h28m
service/wordpress   ClusterIP   10.109.49.212   <none>        80/TCP     4h28m

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/wordpress   1/1     1            1           4h28m

NAME                     READY   AGE
statefulset.apps/mysql   1/1     4h28m

NAME                           READY   STATUS    RESTARTS   AGE
pod/mysql-0                    1/1     Running   0          3h27m
pod/wordpress-cbdfdb58-lkwgc   2/2     Running   0          4h28m

NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/mysql-data-mysql-0   Bound    pvc-46bea269-1d07-405b-9794-6b61329d555d   10Gi       RWO            hostpath       <unset>                 3h27m
```

## Access

http://dev-k8s.techbull.cloud/

Enjoy WordPress Life!

## Tips for troubleshooting

```
kubectl -n <namespace> describe <resource>
kubectl -n <namespace> log <pod_name>
kubectl -n <namespace> exec <pod_name> -c <container_name> -- sh
```

In Container(after exec)
```
cat <log_file>
cat /etc/resolv.conf
nslookup <service_name>
env | grep 'DB\|MYSQL'
```

For invalid env settings, I couldn't access databases, so I wanted to initialize databases.
When initialize databases, you need to delete not only pod/mysql-0 but also persistentvolumeclaim/mysql-data-mysql-0.
```
kubectl -n <namespace> delete pvc mysql-data-mysql-0
kubectl -n <namespace> delete pod mysql-0
```

check docker-entrypoint.sh in official container image.
