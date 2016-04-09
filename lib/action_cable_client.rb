# frozen_string_literal: true
# required gems
require 'em-websocket-client'
require 'forwardable'
require 'active_support/core_ext/string'
require 'json'

# local files
require 'action_cable_client/message_factory'
require 'action_cable_client/message'

class ActionCableClient
  extend Forwardable

  class Commands
    SUBSCRIBE = 'subscribe'
    MESSAGE = 'message'
  end

  attr_reader :_websocket_client, :_uri, :_channel_name
  attr_reader :_message_factory
  # The queue should store entries in the format:
  # [ action, data ]
  attr_accessor :message_queue

  def_delegator :_websocket_client, :disconnect, :disconnected
  def_delegator :_websocket_client, :errback, :errored
  def_delegator :_websocket_client, :stream, :received
  def_delegator :_websocket_client, :connection_completed, :connected?
  def_delegator :_websocket_client, :send_msg, :send_msg

  # @param [String] uri - e.g.: ws://domain:port
  # @param [String] channel - the name of the channel on the Rails server
  #                           e.g.: RoomChannel
  def initialize(uri, channel = '')
    @_channel_name = channel
    @_uri = uri
    @message_queue = []

    @_message_factory = MessageFactory.new(channel)
    # NOTE:
    #   EventMachine::WebSocketClient
    #      https://github.com/mwylde/em-websocket-client/blob/master/lib/em-websocket-client.rb
    #   is a subclass of
    #      https://github.com/eventmachine/eventmachine/blob/master/lib/em/connection.rb
    @_websocket_client = EventMachine::WebSocketClient.connect(_uri)
  end

  # @param [String] action - how the message is being sent
  # @param [Hash] data - the message to be sent to the channel
  def perform(action, data)
    message_queue.push([action, data])
  end

  # callback for received messages as well as
  # what triggers depleting the message queue
  #
  # TODO: have a parameter on this methad that
  #       by default doesn't yield the ping message
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.received do |message|
  #     # the received message will be JSON
  #     puts message
  #   end
  def received
    _websocket_client.stream do | message |
      yield(message)
      deplete_queue
    end
  end

  # callback when the client connects to the server
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.connected do
  #     # do things after the client is connected to the server
  #   end
  def connected
    _websocket_client.callback do
      subscribe
      yield
    end
  end

  private

  def subscribe
    msg = _message_factory.create(Commands::SUBSCRIBE)
    _websocket_client.send_msg(msg.to_json)
  end

  def deplete_queue
    while (message_queue.size > 0)
      action, data = message_queue.pop
      msg = _message_factory.create(Commands::MESSAGE, action, data)
      send_msg(msg.to_json)
    end
  end
end
