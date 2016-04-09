require 'action_cable_client'

EventMachine.run do

  client = ActionCableClient.new("ws://localhost:3000/cable/", 'RoomChannel')

  client.received do | message |
    puts message
  end

  client.perform('speak', { message: 'hello from amc # 3' })
end
