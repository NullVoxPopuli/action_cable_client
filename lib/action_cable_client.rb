# frozen_string_literal: true

# required gems
require 'websocket-eventmachine-client'
require 'forwardable'
require 'active_support/core_ext/string'
require 'json'

# local files
require 'action_cable_client/errors'
require 'action_cable_client/message_factory'
require 'action_cable_client/message'

class ActionCableClient
  extend Forwardable

  class Commands
    SUBSCRIBE = 'subscribe'
    MESSAGE = 'message'
  end

  attr_reader :_websocket_client, :_uri
  attr_reader :_message_factory
  # The queue should store entries in the format:
  # [ action, data ]
  attr_accessor :message_queue, :_subscribed, :_subscribed_callaback, :_pinged_callback

  def_delegator :_websocket_client, :onerror, :errored
  def_delegator :_websocket_client, :send, :send_msg

  # @param [String] uri - e.g.: ws://domain:port
  # @param [String] params - the name of the channel on the Rails server
  #                          or params. This gets sent with every request.
  #                           e.g.: RoomChannel
  # @param [Boolean] connect_on_start - connects on init when true
  #                                   - otherwise manually call `connect!`
  # @param [Hash] headers - HTTP headers to use in the handshake
  def initialize(uri, params = '', connect_on_start = true, headers = {})
    @_uri = uri
    @message_queue = []
    @_subscribed = false

    @_message_factory = MessageFactory.new(params)

    connect!(headers) if connect_on_start
  end

  def connect!(headers = {})
    # Quick Reference for WebSocket::EM::Client's api
    # - onopen - called after successfully connecting
    # - onclose - called after closing connection
    # - onmessage - called when client recives a message. on `message do |msg, type (text or binary)|``
    #             - also called when a ping is received
    # - onerror - called when client encounters an error
    # - onping - called when client receives a ping from the server
    # - onpong - called when client receives a pong from the server
    # - send - sends a message to the server (and also disables any metaprogramming shenanigans :-/)
    # - close - closes the connection and optionally sends close frame to server. `close(code, data)`
    # - ping - sends a ping
    # - pong - sends a pong
    @_websocket_client = WebSocket::EventMachine::Client.connect(uri: @_uri, headers: headers)
  end

  # @param [String] action - how the message is being sent
  # @param [Hash] data - the message to be sent to the channel
  def perform(action, data)
    dispatch_message(action, data)
  end

  # callback for received messages as well as
  # what triggers depleting the message queue
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.received do |message|
  #     # the received message will be JSON
  #     puts message
  #   end
  def received
    _websocket_client.onmessage do |message, _type|
      handle_received_message(message) do |json|
        yield(json)
      end
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
    _websocket_client.onopen do
      subscribe
      yield
    end
  end

  # callback when the client receives a confirm_subscription message
  # from the action_cable server.
  # This is only called once, and signifies that you can now send
  # messages on the channel
  #
  # @param [Proc] block - code to run after subscribing to the channel is confirmed
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.connected {}
  #   client.subscribed do
  #     # do things after successful subscription confirmation
  #   end
  def subscribed(&block)
    self._subscribed_callaback = block
  end

  # @return [Boolean] is the client subscribed to the channel?
  def subscribed?
    _subscribed
  end

  # callback when the server disconnects from the client.
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.connected {}
  #   client.disconnected do
  #     # cleanup after the server disconnects from the client
  #   end
  def disconnected
    _websocket_client.onclose do
      self._subscribed = false
      yield
    end
  end

  def pinged(&block)
    self._pinged_callback = block
  end

  private

  # @param [String] message - the websockt message object
  def handle_received_message(message)
    return if message.empty?
    json = JSON.parse(message)

    if is_ping?(json)
      _pinged_callback&.call(json)
    elsif !subscribed?
      check_for_subscribe_confirmation(json)
    else
      # TODO: do we want to yield any additional things?
      #       maybe just make it extensible?
      yield(json)
    end
  end

  # {"identifier" => "_ping","type" => "confirm_subscription"}
  def check_for_subscribe_confirmation(message)
    message_type = message[Message::TYPE_KEY]
    return unless  Message::TYPE_CONFIRM_SUBSCRIPTION == message_type

    self._subscribed = true
    _subscribed_callaback&.call
  end

  # {"identifier" => "_ping","message" => 1460201942}
  # {"identifier" => "_ping","type" => "confirm_subscription"}
  def is_ping?(message)
    message_identifier = message[Message::TYPE_KEY]
    Message::IDENTIFIER_PING == message_identifier
  end

  def subscribe
    msg = _message_factory.create(Commands::SUBSCRIBE)
    send_msg(msg.to_json)
  end

  def dispatch_message(action, data)
    # can't send messages if we aren't subscribed
    return unless subscribed?

    msg = _message_factory.create(Commands::MESSAGE, action, data)
    json = msg.to_json
    send_msg(json)
  end
end
