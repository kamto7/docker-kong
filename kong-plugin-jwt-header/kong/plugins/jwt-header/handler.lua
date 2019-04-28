local BasePlugin = require "kong.plugins.base_plugin"
local jwt = require "resty.jwt"
local JwtHeaderHandler = BasePlugin:extend()

JwtHeaderHandler.PRIORITY = 1100

function string.split( str, reps )
  local resultStrList = {}
  string.gsub(str,'[^'..reps..']+',function ( w )
      table.insert(resultStrList,w)
  end)
  return resultStrList
end

function string.ucfirst(str)
  return (str:gsub("^%l", string.upper))
end

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
      -- remove client custom jwt headers
      for key, value in pairs(headers) do
        local n, _ = string.find(key, "Jwt")
        if n == 1 then
          ngx.req.clear_header(key)
        end
      end

      -- add jwt headers
      local payload = jwt_obj['payload']
      for key, value in pairs(payload) do
        if (key ~= 'iss' and key ~= 'iat' and key ~= 'exp') then
          nameList = string.split(key, "_") 
          local name = 'Jwt'
          for _, n in pairs(nameList) do
            name = name..'-'..string.ucfirst(n)
          end
          ngx.req.set_header(name, value)
        end
      end
    end
  end
end

return JwtHeaderHandler