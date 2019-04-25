FROM phusion/baseimage:latest

ENV ECS_SYNC_VERSION 3.3.0
RUN apt-get update
RUN apt-get install -y curl wget mysql-client iputils-ping net-tools nginx sqlite unzip openjdk-8-jre

#ecs-sync
RUN mkdir -p /opt/emc/ecs-sync/config
RUN mkdir -p /opt/emc/ecs-sync/logs
WORKDIR /opt/emc/ecs-sync
ADD https://github.com/EMCECS/ecs-sync/releases/download/v$ECS_SYNC_VERSION/ecs-sync-$ECS_SYNC_VERSION.zip /tmp/ecs-sync-$ECS_SYNC_VERSION.zip
RUN cd /tmp; unzip /tmp/ecs-sync-$ECS_SYNC_VERSION.zip
RUN mv /tmp/ecs-sync-$ECS_SYNC_VERSION/ecs-sync-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync
RUN mv /tmp/ecs-sync-$ECS_SYNC_VERSION/ecs-sync-ctl-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync
ADD ./config/create_mysql_user_db.sql /opt/emc/ecs-sync/config/create_mysql_user_db.sql
ADD ./config/create_status_table.sql /opt/emc/ecs-sync/config/create_status_table.sql

#ecs-sync-ui
ADD https://github.com/EMCECS/ecs-sync/releases/download/v$ECS_SYNC_VERSION/ecs-sync-ui-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync/ecs-sync-ui-$ECS_SYNC_VERSION.jar
ADD ./config/ui-config.xml /opt/emc/ecs-sync/config/ui-config.xml
ADD ./config/application-production.yml /opt/emc/ecs-sync/application-production.yml

# Configure nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD ./nginx/default /etc/nginx/sites-available/default

#Fix names of jars
RUN mv /opt/emc/ecs-sync/ecs-sync-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync/ecs-sync.jar; \
    mv /opt/emc/ecs-sync/ecs-sync-ctl-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync/ecs-sync-ctl.jar; \
    mv /opt/emc/ecs-sync/ecs-sync-ui-$ECS_SYNC_VERSION.jar /opt/emc/ecs-sync/ecs-sync-ui.jar

#Setup Runinits
RUN mkdir /etc/service/ecs-sync
ADD ./runit/ecs-sync /etc/service/ecs-sync/run
RUN chmod 0755 /etc/service/ecs-sync/run

RUN mkdir /etc/service/ecs-sync-ui
ADD ./runit/ecs-sync-ui /etc/service/ecs-sync-ui/run
RUN chmod 0755 /etc/service/ecs-sync-ui/run

RUN mkdir /etc/service/nginx
ADD ./runit/nginx /etc/service/nginx/run
RUN chmod 0755 /etc/service/nginx/run
 
EXPOSE 9200
EXPOSE 8080
EXPOSE 80

# Use baseimage-docker's init system.
CMD /usr/bin/mysql -u root -pecssyncroot < /opt/emc/ecs-sync/config/create_mysql_user_db.sql; /usr/bin/mysql -u root -pecssyncroot < /opt/emc/ecs-sync/config/create_status_table.sql; /sbin/my_init
