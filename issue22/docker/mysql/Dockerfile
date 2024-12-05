FROM --platform=linux/x86_64 mysql:8.0.27

ENV TZ Asia/Tokyo
ENV LC_ALL ja_JP.UTF-8
ENV MYSQL_ALLOW_EMPTY_PASSWORD yes

RUN mkdir -p /etc/apt/keyrings
COPY ./mysql.gpg /etc/apt/keyrings/mysql.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian buster mysql-8.0" > /etc/apt/sources.list.d/mysql.list && \
    echo "deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian buster mysql-tools" >> /etc/apt/sources.list.d/mysql.list

RUN apt-get update
RUN apt-get install -y --no-install-recommends\
    locales \
    python \
    vim \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    /var/lib/apt/lists/*

RUN echo "ja_JP.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen ja_JP.UTF-8

# Setup MySQL
RUN touch /var/log/mysqld.log \
    && chown mysql:adm /var/log/mysqld.log

RUN mkdir /var/mysql \
    && chown mysql:adm /var/mysql \
    && rm -rf /etc/mysql/conf.d

COPY ./my.cnf /etc/mysql/
