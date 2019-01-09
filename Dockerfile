FROM kong:1.0.0-alpine

RUN mkdir /app

WORKDIR /app

COPY . .

RUN luarocks install lua-resty-jwt

RUN cd kong-plugin-jwt-header && luarocks make

