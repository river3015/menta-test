FROM nginx:1.27.2-alpine

# Setup UTC+9
RUN apk --update add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata && \
    rm -rf /var/cache/apk/*

# install packages
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
    bash \
    nginx \
    sudo \
    tzdata \
    vim

## nginx
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/dev-k8s.techbull.cloud.conf /etc/nginx/conf.d/dev-k8s.techbull.cloud.conf

EXPOSE 80
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
