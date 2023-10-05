local _M = {}
local k8s_suffix = ".social-network.svc.cluster.local"
local function _StrIsEmpty(s)
  return s == nil or s == ''
end

function _M.Login()
  local ngx = ngx
  local GenericObjectPool = require "GenericObjectPool"
  local UserServiceClient = require "social_network_UserService".UserServiceClient
  local cjson = require "cjson"

  local req_id = tonumber(string.sub(ngx.var.request_id, 0, 15), 16)
  local carrier = {}

  ngx.req.read_body()
  local args = ngx.req.get_uri_args()

  if (_StrIsEmpty(args.username) or _StrIsEmpty(args.password)) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Incomplete arguments")
    ngx.log(ngx.ERR, "Incomplete arguments")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end

  local client = GenericObjectPool:connection(UserServiceClient, "user-service" .. k8s_suffix, 9090)

  local status, ret = pcall(client.Login, client, req_id,
      args.username, args.password, carrier)
  GenericObjectPool:returnConnection(client)

  if not status then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    if (ret.message) then
      ngx.header.content_type = "text/plain"
      ngx.say("User login failure: " .. ret.message)
      ngx.log(ngx.ERR, "User login failure: " .. ret.message)
    else
      ngx.header.content_type = "text/plain"
      ngx.say("User login failure: " .. ret.message)
      ngx.log(ngx.ERR, "User login failure: " .. ret.message)
    end
    ngx.exit(ngx.HTTP_OK)
  else
    ngx.header.content_type = "text/plain"
    ngx.say("Success!")
    ngx.exit(ngx.HTTP_OK)
  end
end

return _M
