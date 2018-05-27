FROM crystallang/crystal:0.24.2

COPY . /app
WORKDIR /app

RUN shards install
RUN crystal build --release client.cr

ENTRYPOINT ./client
