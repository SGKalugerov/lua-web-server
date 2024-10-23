local WebServer = require("webserver")

local server = WebServer:new(8080)

server:addRoute("GET", "/", function()
    return "Welcome to my Lua Web Server!"
end)

server:addRoute("GET", "/about", function()
    return "This is a simple Lua-based web server."
end)

server:addRoute("POST", "/submit", function(body)
    if body then
        local params = WebServer:parseQueryString(body)
        for k, v in pairs(params) do
            print(k, v)
        end

        return "Form submitted with data: " .. body
    else
        return "No data received!"
    end
end)

server:start()
