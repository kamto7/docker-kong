return {
  no_consumer = true,
  fields = {
    -- Describe your plugin's configuration's schema here.
    http_method = {type = "array", default = {"POST"}},
    key_expiration = { type = "number", default = 86400 },
    redis_host = { type = "string", required = true },
    redis_port = { type = "number", default = 6379, },
    redis_password = { type = "string" },
    redis_timeout = { type = "number", default = 2000, }, 
    redis_database = { type = "number", default = 0 }, 
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}