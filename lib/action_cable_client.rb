# required gems
require 'websocket-eventmachine-client'
require 'json'

# local files
require 'action_cable_client/message_factory'
require 'action_cable_client/message'


class ActionCableClient
  class Commands
    SUBSCRIBE = 'subscribe'
    MESSAGE = 'message'
  end


  attr_reader :_websocket_client, :_uri, :_channel_name
  attr_reader :_message_factory
  attr_accessor :_subscribed_to_channel

  def initialize(uri, channel = '')
    _channel_name = channel
    _uri = uri

    _message_factory = MessageFactory.new(_channel_name)
    _websocket_client = WebSocket::EventMachine::Client.connect(uri)
  end

  def connected
    unless subscribed_to_channel
      msg = _message_factory.create(Commands::SUBSCRIBE)
      _websocket_client.send(msg)
      _subscribed_to_channel = true
    end

    yield _websocket_client.onopen
  end

  def disconnected
    yield _websocket_client.onclose
  end

  def received
    yield _websocket_client.onmessage
  end

  def errored
    yield _websocket_client.onerror
  end

  # @param [Hash] message to send to the socket
  def _send(message: message, action: 'default')
    _message_factory.create(Commands::MESSAGE, action, message)
  end

  # Actions!
  def method_missing(method, *args, &block)
    _send(message: args, action: method)
  end
end
