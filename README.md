# Action Cable Client
[![Build Status](https://travis-ci.org/NullVoxPopuli/action_cable_client.svg?branch=master)](https://travis-ci.org/NullVoxPopuli/action_cable_client)[![Code Climate](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/gpa.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client)[![Test Coverage](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/badges/coverage.svg)](https://codeclimate.com/github/NullVoxPopuli/action_cable_client/coverage)


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
