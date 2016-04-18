# frozen_string_literal: true
require 'action_cable_client'

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  def initialize(client)
    @client = client
  end

  def receive_line(data)
    @client.perform('chat', message: data, to: 'user2')
  end
end

# this is just a runnable example from the readme
EventMachine.run do
  client = ActionCableClient.new('ws://localhost:3001?uid=user1', 'MeshRelayChannel')
  client.connected { puts 'successfully connected.' }
  client.received do |message|
    puts message
  end

  EM.open_keyboard(KeyboardHandler, client)
end
