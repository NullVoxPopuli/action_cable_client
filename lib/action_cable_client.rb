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
  attr_accessor :message_queue, :subscribed

  alias subscribed? subscribed

  def_delegator :_websocket_client, :disconnect, :disconnected
  def_delegator :_websocket_client, :errback, :errored
  def_delegator :_websocket_client, :connection_completed, :connected?
  def_delegator :_websocket_client, :send_msg, :send_msg

  # @param [String] uri - e.g.: ws://domain:port
  # @param [String] channel - the name of the channel on the Rails server
  #                           e.g.: RoomChannel
  def initialize(uri, channel = '')
    @_channel_name = channel
    @_uri = uri
    @message_queue = []
    @subscribed = false

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
  # @param [Boolean] skip_pings - by default, messages
  #        with the identifier '_ping' are skipped
  #
  # @example
  #   client = ActionCableClient.new(uri, 'RoomChannel')
  #   client.received do |message|
  #     # the received message will be JSON
  #     puts message
  #   end
  def received(skip_pings = true)
    _websocket_client.stream do |message|
      string = message.data
      json = JSON.parse(string)

      if is_ping?(json)
        check_for_subscribe_confirmation(json) unless subscribed?
        yield(json) unless skip_pings
      else
        yield(json)
      end
      deplete_queue if subscribed?
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

  # {"identifier" => "_ping","type" => "confirm_subscription"}
  def check_for_subscribe_confirmation(message)
    message_type = message[Message::TYPE_KEY]
    self.subscribed = true if Message::TYPE_CONFIRM_SUBSCRIPTION == message_type
  end

  # {"identifier" => "_ping","message" => 1460201942}
  # {"identifier" => "_ping","type" => "confirm_subscription"}
  def is_ping?(message)
    message_identifier = message[Message::IDENTIFIER_KEY]
    Message::IDENTIFIER_PING == message_identifier
  end

  def subscribe
    msg = _message_factory.create(Commands::SUBSCRIBE)
    _websocket_client.send_msg(msg.to_json)
  end

  def deplete_queue
    until message_queue.empty?
      action, data = message_queue.pop
      msg = _message_factory.create(Commands::MESSAGE, action, data)
      send_msg(msg.to_json)
    end
  end
end
