#!/usr/bin/env tarantool

local log_module = require('log')
local json_module = require('json')

local KEY_ALREADY_EXIST = 409
local INCORRECT_BODY = 400
local KEY_NOT_EXIST = 404
local SUCCESS = 200

log_module.info('Tarantool start')

box.cfg{
    log_format = 'plain',
    log='logs/server_logs.txt'
}

box.once('init', function()
		box.schema.create_space('kv_server',
			{
				format = {
					{ name = 'key',   type = 'string' },
					{ name = 'value', type = '*' }
				}
			}
		)
		box.space.kv_server:create_index(
            'primary', 
			{type = 'hash', parts = {1, 'string'}}
		)
	end
)



local server_post = function(request)
    local json = request:json()
    log_module.info(json)
    local key = json['key']
    local value = json['value']

    if key == nil or value == nil then
        log_module.info('POST: error %s', INCORRECT_BODY)
        local response = request:render{json = { info = "key or value missed" }}
		response.status = INCORRECT_BODY
		return response
    end

    if box.space.kv_server.index.primary:select{key}[1] then
        log_module.info('POST: error %s', KEY_ALREADY_EXIST)
        local response = request:render{json = { info = "key already exist" }}
		response.status = KEY_ALREADY_EXIST
		return response
    end
    box.space.kv_server:insert({key, value})
    log_module.info('POST: inserted key-> ' ..key.. ' value-> ' ..value)
    local response = request:render{json = { info = "successfully created" }}
	response.status = SUCCESS
    return response
end

local server_put = function(request)
    local key = request:stash('id')
    log_module.info('key -> %s',key)

    local json = request:json()
    log_module.info(json)
    local value = json['value']

    if key == nil or value == nil then
        log_module.info('PUT: error %s', INCORRECT_BODY)
        local response = request:render{json = { info = "key or value missed" }}
		response.status = INCORRECT_BODY
		return response
    end

	if not box.space.kv_server.index.primary:select{key}[1] then
        log_module.info('PUT: error %s', KEY_NOT_EXIST)
        local response = request:render{json = { info = "key doesn't exist" }}
		response.status = KEY_NOT_EXIST
		return response
	end

	box.space.kv_server:update(key, {{'=', 2, value}})
    log_module.info('PUT: updated key-> ' ..key.. ' value-> ' ..value)

	local response = request:render{json = { info = "successfully updated" }}
	response.status = SUCCESS
	return resp
end

local server_get = function(request)
    local key = request:stash('id')
    log_module.info('key -> %s',key)
    log_module.info(key)

    if key == nil then
        log_module.info('GET: error %s', INCORRECT_BODY)
        local response = request:render{json = { info = "key missed" }}
		response.status = INCORRECT_BODY
		return response
    end

    local tuple = box.space.kv_server.index.primary:select{key}
    if not tuple[1] then
        log_module.info('GET: error %s', KEY_NOT_EXIST)
        local response = request:render{json = { info = "key doesn't exist" }}
		response.status = KEY_NOT_EXIST
		return response
    end

    key = tuple[1][1]
    value = tuple[1][2]

    log_module.info('GET: key-> ' ..key.. ' value-> ' ..value)

    local response = request:render{json = {key, value}}
	response.status = SUCCESS
	return response
end


local server_delete = function(request)
    local key = request:stash('id')
    log_module.info('key -> %s',key)

    if key == nil then
        log_module.info('DELETE: error %s', INCORRECT_BODY)
        local response = request:render{json = { info = "key missed" }}
		response.status = INCORRECT_BODY
		return response
    end

    local tuple = box.space.kv_server.index.primary:select{key}
    if not tuple[1] then
        log_module.info('DELETE: error %s', KEY_NOT_EXIST)
        local response = request:render{json = { info = "key doesn't exist" }}
		response.status = KEY_NOT_EXIST
		return response
    end

    box.space.kv_server:delete{key}

    log_module.info('DELETE: key-> ' ..key.. ' value-> ' ..value)

    local response = request:render{json = { info = "successfully deleted" }}
	response.status = SUCCESS
	return response
end



local server = require('http.server').new('127.0.0.1', 3301)
local router = require('http.router').new()
server:set_router(router)

router:route({ path = '/kv',     method = 'POST'  }, server_post)
router:route({ path = '/kv/:id', method = 'PUT'   }, server_put)
router:route({ path = '/kv/:id', method = 'GET'   }, server_get)
router:route({ path = '/kv/:id', method = 'DELETE'}, server_delete)

log_module.info('kv server start')
server:start()