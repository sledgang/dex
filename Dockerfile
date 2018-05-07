FROM ruby:2.5.1-slim-stretch

RUN apt-get update && apt-get install -y --no-install-recommends ruby-dev g++ make git

RUN mkdir /opt/dex

ADD . /opt/dex
WORKDIR /opt/dex

RUN rake install

CMD rake
