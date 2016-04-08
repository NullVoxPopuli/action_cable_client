# Action Cable Client


## Usage

```ruby
require 'action_cable_client'

#EM.run do

  client = ActionCableClient.new(
    uri: 'ws://localhost:3000/cable/',
    channel: 'my-channel'
  )


  client.connected do

  end

  client.disconnected do

  end

  client.received do

  end

  client.speak, { message: 'Hello World'}

#end
```
