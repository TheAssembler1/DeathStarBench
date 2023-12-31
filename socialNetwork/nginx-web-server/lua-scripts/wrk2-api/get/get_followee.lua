local _M = {}
local k8s_suffix = ".social-network.svc.cluster.local"
local function _StrIsEmpty(s)
  return s == nil or s == ''
end

local function _LoadFollwee(data)
  local followee_list = {}
  for _, followee in ipairs(data) do
    local new_followee = {}
    new_followee["followee_id"] = tostring(followee)
    table.insert(followee_list, new_followee)
  end
  return followee_list
end





function _M.GetFollowee()
  local ngx = ngx
  local GenericObjectPool = require "GenericObjectPool"
  local SocialGraphServiceClient = require "social_network_SocialGraphService".SocialGraphServiceClient
  local cjson = require "cjson"
  local jwt = require "resty.jwt"
  local liblualongnumber = require "liblualongnumber"

  local req_id = tonumber(string.sub(ngx.var.request_id, 0, 15), 16)
  local carrier = {}

  ngx.req.read_body()
  local post = ngx.req.get_uri_args()
  local user_id = tonumber(post.user_id)

  if false then
  else
    local client = GenericObjectPool:connection(
      SocialGraphServiceClient, "social-graph-service" .. k8s_suffix, 9090)
    local status, ret = pcall(client.GetFollowees, client, req_id,
        user_id, carrier)
    GenericObjectPool:returnConnection(client)
    if not status then
      ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
      if (ret.message) then
        ngx.header.content_type = "text/plain"
        ngx.say("Get user-timeline failure: " .. ret.message)
        ngx.log(ngx.ERR, "Get user-timeline failure: " .. ret.message)
      else
        ngx.header.content_type = "text/plain"
        ngx.say("Get user-timeline failure: " .. ret.message)
        ngx.log(ngx.ERR, "Get user-timeline failure: " .. ret.message)
      end
      ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    else
      local followee_list = _LoadFollwee(ret)
      ngx.header.content_type = "application/json; charset=utf-8"
      ngx.say(cjson.encode(followee_list) )
    end
  end
end
return _M
