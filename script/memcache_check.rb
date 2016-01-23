#!/usr/bin/env ruby

require 'socket'
require 'json'
require 'net/http'

begin
	TCPSocket.open('127.0.0.1', 11211).close
rescue Errno::ECONNREFUSED
	params = {
		'to' => 'Phil Kulak <phil@kulak.us>',
		'from' => 'Mealfire Support <support@mealfire.com>',
		'subject' => 'Memcache',
		'textBody' => 'Memcache is down!!!'
	}

	res = Net::HTTP.new('api.postmarkapp.com', 80).start do |http|
        req = Net::HTTP::Post.new('/email')
        req.add_field('Accept', 'application/json')
        req.add_field('Content-Type', 'application/json')
        req.add_field('X-Postmark-Server-Token', '...')
        req.body = params.to_json
        http.request(req)
    end
end