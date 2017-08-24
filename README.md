# Action Cable Client
[![Gem Version](https://badge.fury.io/rb/action_cable_client.svg)](https://badge.fury.io/rb/action_cable_client)
[![Build Status](https://travis-ci.org/NullVoxPopuli/action_cable_client.svg?branch=master)](https://travis-ci.org/NullVoxPopuli/action_cable_client)
[![Code Climate](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/gpa.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client)
[![Test Coverage](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/coverage.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/coverage)
[![Dependency Status](https://gemnasium.com/badges/github.com/NullVoxPopuli/action_cable_client.svg)](https://gemnasium.com/github.com/NullVoxPopuli/action_cable_client)

This gem is a wrapper around [websocket-eventmachine-client](https://github.com/imanel/websocket-eventmachine-client), and supports the Rails Action Cable protocol.

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
 - `subscribed {}`
 - `errored { |msg| }`
 - `received { |msg }`
 - `pinged { |msg| }`


#### Connecting on initialization is also configurable.

```ruby
client = ActionCableClient.new(uri, 'RoomChannel', false)
client.connect!(headers = {})
```

this way if you also enable ping receiving via
```ruby
client.received(false) do |json|
  # now pings will be here as well, because skip_pings is set to false
end
```

you could track the time since you last received a ping, if you haven't received one in a while, it could be that your client is disconnected.

To reconnect,

```ruby
client.connect!
```

#### Sending additional params

```ruby
params = { channel: 'RoomChannel', favorite_color: 'blue' }
client = ActionCableClient.new(uri, params)
```

then on the server end, in your Channel, `params` will give you:
```
{
       "channel" => "RoomChannel",
"favorite_color" => "blue"
}
```

#### Using Headers


```ruby
params = { channel: 'RoomChannel', favorite_color: 'blue' }
client = ActionCableClient.new(uri, params, true, {
  'Authorization' => 'Bearer token'
})
```


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
  - Make sure that the `action` string matches the data-handling method name on your ActionCable server.
  - Your message JSON should look like this:
    - `{"command":"message","identifier":"{\"channel\":\"MeshRelayChannel\"}","data":"{\"to\":\"user1\",\"message\":\"hello from user2\",\"action\":\"chat\"}"}`
    - Received messages should look about the same

4. Notes:
  - Every message sent to the server has a `command` and `identifier` key.
  - Ping messages from the action cable server look like:
    - `{ "type" => "ping", "message" =>  1461845503 }`
  - The channel value must match the `name` of the channel class on the ActionCable server.
  - `identifier` and `data` are redundantly jsonified. So, for example (in ruby):
```ruby
payload = {
  command: 'command text',
  identifier: { channel: 'MeshRelayChannel' }.to_json,
  data: { to: 'user', message: 'hi', action: 'chat' }.to_json
}.to_json
```


## Contributing

1. Fork it ( https://github.com/NullVoxPopuli/action_cable_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
