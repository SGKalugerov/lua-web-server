local socket = require("socket")

local WebServer = {}

function WebServer:new(port)
    local obj = {}
    obj.port = port or 8080
    obj.routes = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function WebServer:addRoute(method, path, handler)
    self.routes[path] = self.routes[path] or {}
    self.routes[path][method] = handler
end

function WebServer:start()
    local server = assert(socket.bind("*", self.port))
    print("Server started on port " .. self.port)

    while true do
        local client = server:accept()
        client:settimeout(10)

        local request, err = client:receive()

        if not err then
            local method, path, headers = self:parseRequest(client, request)


            local body = nil
            if method == "POST" then
                body = self:readBody(client, headers)
            end

            local handler = self:findHandler(method, path)


            if handler then
                local response = handler(body)
                client:send(self:formatResponse(200, response))
            else
                client:send(self:formatResponse(404, "Not Found"))
            end
        end

        client:close()
    end
end

function WebServer:parseRequest(client, request)
    local method, path = request:match("^(%w+)%s(/[%w_%.%-/]*)%sHTTP")

    local headers = {}
    while true do
        local line = client:receive()
        if line == "" or not line then break end
        local key, value = line:match("^(.-):%s*(.*)")
        if key and value then
            headers[key:lower()] = value
        end
    end

    return method, path, headers
end

function WebServer:parseQueryString(query)
    local result = {}
    for pair in string.gmatch(query, "([^&]+)") do
        local key, value = string.match(pair, "([^=]+)=([^=]+)")
        if key and value then
            result[key] = value
        end
    end
    return result
end

function WebServer:readBody(client, headers)
    local length = tonumber(headers["content-length"])
    if length and length > 0 then
        return client:receive(length)
    else
        return nil
    end
end

function WebServer:findHandler(method, path)
    if self.routes[path] and self.routes[path][method] then
        return self.routes[path][method]
    else
        return nil
    end
end

function WebServer:formatResponse(status_code, body)
    local reason_phrase = {
        [200] = "OK",
        [404] = "Not Found"
    }

    local response = {
        "HTTP/1.1 " .. status_code .. " " .. reason_phrase[status_code],
        "Content-Type: text/plain",
        "Content-Length: " .. #body,
        "Connection: close",
        "",
        body
    }

    return table.concat(response, "\r\n")
end

return WebServer
