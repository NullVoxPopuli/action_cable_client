require 'action_cable_client'

EM.run do

  client = ActionCableClient.new("ws://localhost:3000/cable/", 'room_channel')

  client.connected do
    puts 'Connected Received'
  end

  client.disconnected do
    puts "Disconnected"
  end  

  client.received do | message, type |
    puts "Received" + message + " " + type.to_s
  end

  client.errored do |e|
    puts "Error: " + e.to_s
  end
end

