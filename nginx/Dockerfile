FROM nginx:1.19.6

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove && \
    apt-get clean

RUN rm /etc/nginx/conf.d/*
COPY *.conf /etc/nginx/conf.d/