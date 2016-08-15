# frozen_string_literal: true
require 'action_cable_client'

# this is just a runnable example from the readme
EventMachine.run do
  client = ActionCableClient.new('ws://localhost:3001?uid=124', 'MeshRelayChannel')
  client.connected { puts 'successfully connected.' }
  client.received do |message|
    puts message
  end

  client.perform('speak', message: 'hello from amc')
end
