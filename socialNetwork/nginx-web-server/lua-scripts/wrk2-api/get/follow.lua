local _M = {}
local k8s_suffix = ".social-network.svc.cluster.local"
local function _StrIsEmpty(s)
  return s == nil or s == ''
end

function _M.Follow()
  local ngx = ngx
  local GenericObjectPool = require "GenericObjectPool"
  local social_network_SocialGraphService = require "social_network_SocialGraphService"
  local SocialGraphServiceClient = social_network_SocialGraphService.SocialGraphServiceClient

  local req_id = tonumber(string.sub(ngx.var.request_id, 0, 15), 16)
  local carrier = {}

  ngx.req.read_body()
  local post = ngx.req.get_uri_args()

  local client = GenericObjectPool:connection(
      SocialGraphServiceClient, "social-graph-service" .. k8s_suffix, 9090)

  local status
  local err
  if (not _StrIsEmpty(post.user_id) and not _StrIsEmpty(post.followee_id)) then
    status, err = pcall(client.Follow, client,req_id,
        tonumber(post.user_id), tonumber(post.followee_id), carrier )
  elseif (not _StrIsEmpty(post.user_name) and not _StrIsEmpty(post.followee_name)) then
    status, err = pcall(client.FollowWithUsername, client,req_id,
        post.user_name, post.followee_name, carrier )
  else
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Incomplete arguments")
    ngx.log(ngx.ERR, "Incomplete arguments")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end

  if not status then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    if (err.message) then
      ngx.say("Follow Failed: " .. err.message)
      ngx.log(ngx.ERR, "Follow Failed: " .. err.message)
    else
      ngx.say("Follow Failed: " .. err)
      ngx.log(ngx.ERR, "Follow Failed: " .. err)
    end
    client.iprot.trans:close()
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  else
    ngx.say("Success!")
    GenericObjectPool:returnConnection(client)
  end

end

return _M
