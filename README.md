# Action Cable Client
[![Build Status](https://travis-ci.org/NullVoxPopuli/action_cable_client.svg?branch=master)](https://travis-ci.org/NullVoxPopuli/action_cable_client)
[![Code Climate](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/gpa.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client)
[![Test Coverage](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/coverage.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/coverage)


## Usage

```ruby
require 'action_cable_client'

EventMachine.run do

  client = ActionCableClient.new(
    "ws://localhost:3000/cable/",
    'RoomChannel')

  # called whenever a message is received from the server
  client.received do | message |
    puts message
  end

  # adds to a queue that is purged upon receiving of
  # a ping from the server
  client.perform('speak', { message: 'hello from amc' })
end
```
