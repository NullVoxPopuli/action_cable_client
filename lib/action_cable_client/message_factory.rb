# frozen_string_literal: true
class ActionCableClient
  class MessageFactory
    attr_reader :_channel

    # @param [String] channel - the name of the subscribed channel
    def initialize(channel)
      @_channel = channel
      @identifier = {channel: _channel)
    end

    # @param [String] command - the type of message that this is
    # @param [String] action - the action that is performed to send this message
    # @param [Hash] message - the data to send
    def create(command, action = '', message = nil)
      data = build_data(action, message)
      Message.new(command, identifier, data)
    end

    # @param [String] action - the action that is performed to send this message
    # @param [Hash] message - the data to send
    # @return [Hash] The data that will be included in the message
    def build_data(action, message)
      message.merge(action: action) if message.is_a?(Hash)
    end

    # the ending result should look like
    # "{"channel":"RoomChannel"}" but that's up to
    # the Mesage to format it
#     def identifier
#       { channel: _channel }
#     end
  end
end
