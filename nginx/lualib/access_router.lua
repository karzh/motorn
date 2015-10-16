-- firstly, authorize the user
local user = jose.auth_by_header()

-- capture the first part of the request path
local captures, err = ngx.re.match(ngx.var.uri, "^/([^/]+)/?.*$", "ajo")
if (err ~= nil or captures[1] == nil) then
  ngx.log(ngx.ERR, "no match in path")
  ngx.exit(ngx.HTTP_BAD_REQUEST)
end

-- look up the first segement of the request path in the routes cache
local route = captures[1]
local target = ngx.shared.api_routes:get(route)
if target == nil then
  -- if routes have already been loaded, then we don't really exist
  if ngx.shared.api_routes:get("_loaded") ~= nil then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end

  -- load routes into the route cache and try our route again
  ngx.location.capture("/_preload")
  target = ngx.shared.api_routes:get(route)
  if target == nil then
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
end

-- set the upstream target
ngx.var.target = target