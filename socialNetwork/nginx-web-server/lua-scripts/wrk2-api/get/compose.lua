local _M = {}
local k8s_suffix = ".social-network.svc.cluster.local"
local function _StrIsEmpty(s)
  return s == nil or s == ''
end

function _M.ComposePost()
  local ngx = ngx
  local cjson = require "cjson"

  local GenericObjectPool = require "GenericObjectPool"
  local social_network_ComposePostService = require "social_network_ComposePostService"
  local ComposePostServiceClient = social_network_ComposePostService.ComposePostServiceClient

  GenericObjectPool:setMaxTotal(512)

  local req_id = tonumber(string.sub(ngx.var.request_id, 0, 15), 16)


  ngx.req.read_body()
  local post = ngx.req.get_uri_args()

  if (_StrIsEmpty(post.user_id) or _StrIsEmpty(post.username) or
      _StrIsEmpty(post.post_type) or _StrIsEmpty(post.text)) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Incomplete arguments")
    ngx.log(ngx.ERR, "Incomplete arguments")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
  end

  local status, ret

  local client = GenericObjectPool:connection(
      ComposePostServiceClient, "compose-post-service" .. k8s_suffix, 9090)

  local carrier = {}

  if (not _StrIsEmpty(post.media_ids) and not _StrIsEmpty(post.media_types)) then
    status, ret = pcall(client.ComposePost, client,
        req_id, post.username, tonumber(post.user_id), post.text,
        cjson.decode(post.media_ids), cjson.decode(post.media_types),
        tonumber(post.post_type), carrier)
  else
    status, ret = pcall(client.ComposePost, client,
        req_id, post.username, tonumber(post.user_id), post.text,
        {}, {}, tonumber(post.post_type), carrier)
  end
  if not status then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    if (ret.message) then
      ngx.say("compost_post failure 1: " .. ret.message)
      ngx.log(ngx.ERR, "compost_post failure: " .. ret.message)
    else
      ngx.say("compost_post failure 2: " .. ret)
      ngx.log(ngx.ERR, "compost_post failure: " .. ret)
    end
    client.iprot.trans:close()
    ngx.exit(ngx.status)
  end

  GenericObjectPool:returnConnection(client)
  ngx.status = ngx.HTTP_OK
  ngx.say("Successfully upload post")
  ngx.exit(ngx.status)
end

return _M
