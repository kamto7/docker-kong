local BasePlugin = require "kong.plugins.base_plugin"
local redis = require "resty.redis"
local IdempotencyKeyHandler = BasePlugin:extend()

local function is_present(str)
  return str and str ~= "" and str ~= null
end

local function is_include(value, tab)
  for k,v in pairs(tab) do
    if v == value then
        return true
    end
  end
  return false
end

IdempotencyKeyHandler.PRIORITY = 800

function IdempotencyKeyHandler:new()
  IdempotencyKeyHandler.super.new(self, "idempotency-key")
end

function IdempotencyKeyHandler:access(conf)
  IdempotencyKeyHandler.super.access(self)
  local headers = ngx.req.get_headers()
  local method = ngx.req.get_method()
  local IdempotencyKey = headers['Idempotency-Key']
  local http_method = conf.http_method
  if IdempotencyKey and is_include(method, http_method) then
    local red = redis:new()
    local sock_opts = {}
    red:set_timeout(conf.redis_timeout)
    -- use a special pool name only if redis_database is set to non-zero
    -- otherwise use the default pool name host:port
    sock_opts.pool = conf.redis_database and
                     conf.redis_host .. ":" .. conf.redis_port ..
                     ":" .. conf.redis_database
    local ok, err = red:connect(conf.redis_host, conf.redis_port,
                                sock_opts)
    if not ok then
      kong.log.err("failed to connect to Redis: ", err)
      return kong.response.exit(500, { message = "An unexpected error occurred" })
    end

    local times, err = red:get_reused_times()
    if err then
      kong.log.err("failed to get connect reused times: ", err)
      return kong.response.exit(500, { message = "An unexpected error occurred" })
    end

    if times == 0 then
      if is_present(conf.redis_password) then
        local ok, err = red:auth(conf.redis_password)
        if not ok then
          kong.log.err("failed to auth Redis: ", err)
          return kong.response.exit(500, { message = "An unexpected error occurred" })
        end
      end

      if conf.redis_database ~= 0 then
        -- Only call select first time, since we know the connection is shared
        -- between instances that use the same redis database

        local ok, err = red:select(conf.redis_database)
        if not ok then
          kong.log.err("failed to change Redis database: ", err)
          return kong.response.exit(500, { message = "An unexpected error occurred" })
        end
      end
    end

    local cache_key = "idempotency:key::" .. IdempotencyKey
    local exists, err = red:exists(cache_key)
    if err then
      kong.log.err("failed to query Redis: ", err)
      return kong.response.exit(500, { message = "An unexpected error occurred" })
    end

    if exists ~= 0 then
      return kong.response.exit(409, { message = "The request conflicts with another request (due to using the same idempotent key)." })
    end

    red:set(cache_key, 1)
    red:expire(cache_key, conf.key_expiration)

    local ok, err = red:set_keepalive(10000, 100)
    if not ok then
      kong.log.err("failed to set Redis keepalive: ", err)
      return kong.response.exit(500, { message = "An unexpected error occurred" })
    end
  end
end

return IdempotencyKeyHandler