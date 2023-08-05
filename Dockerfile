# FROM debian:bookworm-20230411-slim
# 
# RUN apt-get update && apt-get install -y caddy && rm -rf /var/lib/apt/lists/*
# 
# COPY ./output /app
# WORKDIR /app
# 
# CMD caddy RUN

FROM pierrezemb/gostatic
COPY ./dist/ /srv/http/

