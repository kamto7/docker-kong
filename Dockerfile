FROM kong

RUN mkdir /app

WORKDIR /app

COPY . .

RUN luarocks install lua-resty-jwt

RUN cd kong-plugin-jwt-header && luarocks make

RUN cd kong-plugin-idempotency-key && luarocks make

