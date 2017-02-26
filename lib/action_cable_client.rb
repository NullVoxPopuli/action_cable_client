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

  attr_reader :_websocket_client, :_uri, :_channel_name, :_queued_send
  attr_reader :_message_factory
  # [ action, data ]
  attr_accessor :message_queue, :_subscribed, :_subscribed_callaback

  def_delegator :_websocket_client, :errback, :errored
  def_delegator :_websocket_client, :send_msg, :send_msg

  # @param [String] uri - e.g.: ws://domain:port
  # @param [String] channel - the name of the channel on the Rails server
  #                           e.g.: RoomChannel
  # TODO: @param [Hash] params - optionally provide additional params to pass
  #                              upon connection and subscription??
  # @param [Boolean] queued_send - optionally send messages after a ping
  #                                is received, rather than instantly
  def initialize(uri, channel = '', queued_send = false)
    @_channel_name = channel
    @_uri = uri
    @_queued_send = queued_send
    @message_queue = []
    @_subscribed = false

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
    if _queued_send
      message_queue.push([action, data])
    else
      dispatch_message(action, data)
    end
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
      handle_received_message(message, skip_pings) do |json|
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
    _websocket_client.callback do
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
    _websocket_client.disconnect do
      self._subscribed = false
      yield
    end
  end

  private

  # @param [WebSocket::Frame::Incoming::Client] message - the websockt message object
  #        This object is from the websocket-ruby gem:
  #         https://github.com/imanel/websocket-ruby/blob/master/lib/websocket/frame/incoming/client.rb
  #
  #   [9] pry(#<ActionCableClient>)> ap message.methods - Object.instance_methods
  #
  #     [ 0]                     <<(data)  WebSocket::Frame::Incoming::Client (WebSocket::Frame::Incoming)
  #     [ 1]                   code()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 2]                  code=(arg1)  WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 3]                   data()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 4]                  data=(arg1)  WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 5]               decoded?()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Incoming)
  #     [ 6]                  error()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 7]                 error=(arg1)  WebSocket::Frame::Incoming::Client (WebSocket::ExceptionHandler)
  #     [ 8]                 error?()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [ 9]      incoming_masking?()      WebSocket::Frame::Incoming::Client
  #     [10] initialize_with_rescue(*args) WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [11]                   next(*args) WebSocket::Frame::Incoming::Client (WebSocket::Frame::Incoming)
  #     [12]       next_with_rescue(*args) WebSocket::Frame::Incoming::Client (WebSocket::Frame::Incoming)
  #     [13]    next_without_rescue()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Incoming)
  #     [14]      outgoing_masking?()      WebSocket::Frame::Incoming::Client
  #     [15]          support_type?()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [16]       supported_frames()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [17]                   type()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #     [18]                version()      WebSocket::Frame::Incoming::Client (WebSocket::Frame::Base)
  #
  # None of this really seems that importont, other than `data`
  #
  # @param [Boolean] skip_pings - by default, messages
  #        with the identifier '_ping' are skipped
  def handle_received_message(message, skip_pings = true)
    string = message.data
    return if string.empty?
    json = JSON.parse(string)

    if is_ping?(json)
      yield(json) unless skip_pings
    elsif !subscribed?
      check_for_subscribe_confirmation(json)
    else
      # TODO: do we want to yield any additional things?
      #       maybe just make it extensible?
      yield(json)
    end

    deplete_queue if _queued_send
  end

  # {"identifier" => "_ping","type" => "confirm_subscription"}
  def check_for_subscribe_confirmation(message)
    message_type = message[Message::TYPE_KEY]
    if Message::TYPE_CONFIRM_SUBSCRIPTION == message_type
      self._subscribed = true
      _subscribed_callaback.call if _subscribed_callaback
    end
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

  def deplete_queue
    # if we haven't yet subscribed, don't deplete the queue
    if subscribed?
      # only try to send if we have messages to send
      until message_queue.empty?
        action, data = message_queue.pop
        dispatch_message(action, data)
      end
    end
  end

  def dispatch_message(action, data)
    # can't send messages if we aren't subscribed
    if subscribed?
      msg = _message_factory.create(Commands::MESSAGE, action, data)
      json = msg.to_json
      send_msg(json)
    end
  end
end
