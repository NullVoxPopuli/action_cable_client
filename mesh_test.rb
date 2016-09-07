# frozen_string_literal: true
# require 'action_cable_client'

current_dir = File.dirname(__FILE__)
# set load path (similar to how gems require files (relative to lib))

lib = current_dir + '/lib/'
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require current_dir + '/lib/action_cable_client'

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  def initialize(client)
    @client = client
  end

  def receive_line(data)
    @client.perform('chat', message: data, to: '124')
  end
end

# this is just a runnable example from the readme
EventMachine.run do
  # client = ActionCableClient.new('ws://mesh-relay-in-us-1.herokuapp.com', 'MeshRelayChannel')
  client = ActionCableClient.new('ws://localhost:3000?uid=124', 'MeshRelayChannel')
  client.connected { puts 'successfully connected.' }
  client.received do |message|
    puts client.subscribed?
    puts message
  end

  client.errored do |*args|
    puts 'error'
    puts args
  end

  client.disconnected do
    puts 'disconnected'
  end

  EM.open_keyboard(KeyboardHandler, client)
end
