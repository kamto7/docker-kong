local BasePlugin = require "kong.plugins.base_plugin"
local jwt = require "resty.jwt"
local JwtHeaderHandler = BasePlugin:extend()

function JwtHeaderHandler:new()
  JwtHeaderHandler.super.new(self, "jwt-header")
end

function JwtHeaderHandler:access(config)
  JwtHeaderHandler.super.access(self)
  local headers = ngx.req.get_headers()
  local Authorization = headers['Authorization']
  if (Authorization) then
    local jwt_token = string.gsub(Authorization, "Bearer ", "") 
    local jwt_obj = jwt:load_jwt(jwt_token)
    
    if (jwt_obj['payload']) then
      local payload = jwt_obj['payload']
      table.remove(payload, 'iss')
      table.remove(payload, 'iat')
      table.remove(payload, 'exp')
      for key, value in pairs(payload) do
        local name = 'x-'..string.gsub(key, "_", "-")
        ngx.req.set_header(name, value)
      end
    end
  end
end

return JwtHeaderHandler