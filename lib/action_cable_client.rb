require 'websocket-eventmachine-client'
require 'json'

class ActionCableClient

  attr_reader :_websocket_client, :_uri, :_channel_name

  def initialize(uri, channel = '')
    _channel_name = channel
    _uri = uri

    _websocket_client = WebSocket::EventMachine::Client.connect(uri)
  end

  def connected

  end

  def disconnected

  end

  def received

  end

  # Actions!
  def method_missing(method, *args, &block)

  end
end
