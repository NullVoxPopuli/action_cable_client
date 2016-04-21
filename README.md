# Action Cable Client
[![Gem Version](https://badge.fury.io/rb/action_cable_client.svg)](https://badge.fury.io/rb/action_cable_client)
[![Build Status](https://travis-ci.org/NullVoxPopuli/action_cable_client.svg?branch=master)](https://travis-ci.org/NullVoxPopuli/action_cable_client)
[![Code Climate](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/gpa.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client)
[![Test Coverage](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/coverage.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/coverage)
[![Dependency Status](https://gemnasium.com/badges/github.com/NullVoxPopuli/action_cable_client.svg)](https://gemnasium.com/github.com/NullVoxPopuli/action_cable_client)


There are quite a few WebSocket Servers out there. The popular ones seem to be: [faye-websocket-ruby](https://github.com/faye/faye-websocket-ruby), [em-websockets](https://github.com/igrigorik/em-websocket). The client-only websocket gems are kinda hard to find, and are only raw websocket support. Rails has a thin layer on top of web sockets to help manage subscribing to channels and send/receive on channels.

This gem is a wrapper around [em-websocket-client](https://github.com/mwylde/em-websocket-client/), and supports the Rails Action Cable protocol.

## Usage

```ruby
require 'action_cable_client'

EventMachine.run do

  uri = "ws://localhost:3000/cable/"
  client = ActionCableClient.new(uri, 'RoomChannel')
  # the connected callback is required, as it triggers
  # the actual subscribing to the channel but it can just be
  # client.connected {}
  client.connected { puts 'successfully connected.' }

  # called whenever a message is received from the server
  client.received do | message |
    puts message
  end

  # adds to a queue that is purged upon receiving of
  # a ping from the server
  client.perform('speak', { message: 'hello from amc' })
end
```

This example is compatible with [this version of a small Rails app with Action Cable](https://github.com/NullVoxPopuli/mesh-relay/tree/2ed88928d91d82b88b7878fcb97e3bd81977cfe8)



The available hooks to tie in to are:
 - `disconnected {}`
 - `connected {}`
 - `errored { |msg| }`
 - `received { |msg }`

## Demo

[![Live Demo](http://img.youtube.com/vi/x9D1wWsVHMY/mqdefault.jpg)](http://www.youtube.com/watch?v=x9D1wWsVHMY&hd=1)

Action Cable Client Demo on YouTube (1:41)

[Here is a set of files in a gist](https://gist.github.com/NullVoxPopuli/edfcbbe91a7877e445cbde84c7f05b37) that demonstrate how different `action_cable_client`s can communicate with eachother.

## The Action Cable Protocol

There really isn't that much to this gem. :-)

1. Connect to the Action Cable URL
2. After the connection succeeds, send a subscribe message
  - The subscribe message JSON should look like this
    - `{"command":"subscribe","identifier":"{\"channel\":\"MeshRelayChannel\"}"}`
  - You should receive a message like this:
    - `{"identifier"=>"{\"channel\":\"MeshRelayChannel\"}", "type"=>"confirm_subscription"}`
3. Once subscribed, you can send messages.
  - Make sure that the command string matches the data-handling method name on your ActionCable server.
  - Your message JSON should look like this:
    - `{"command":"message","identifier":"{\"channel\":\"MeshRelayChannel\"}","data":"{\"to\":\"user1\",\"message\":\"hello from user2\",\"action\":\"chat\"}"}`
    - Received messages should look about the same

4. Notes:
  - Every message sent to the server has a `command` and `identifier` key. 
  - The channel value must match the `name` of the channel class on the ActionCable server.
  - `identifier` and `data` are redundantly jsonified. So, for example (in ruby):
```ruby
payload = {
  command: 'command text',
  identifier: { channel: 'MeshRelayChannel' }.to_json,
  data: { to: 'user', message: 'hi' }.to_json
}.to_json
```


## Contributing

1. Fork it ( https://github.com/NullVoxPopuli/action_cable_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
