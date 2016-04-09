# Action Cable Client
[![Build Status](https://travis-ci.org/NullVoxPopuli/action_cable_client.svg?branch=master)](https://travis-ci.org/NullVoxPopuli/action_cable_client)
[![Code Climate](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/gpa.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client)
[![Test Coverage](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/coverage.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/coverage)

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
