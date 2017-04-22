# frozen_string_literal: true
class ActionCableClient
  class MessageFactory
    attr_reader :channel, :identifier

    # @param [String or Hash] channel - the name of the subscribed channel, or
    #   a hash that includes the :channel key and any other params to send.
    def initialize(channel)
      # the ending result should look like
      # "{"channel":"RoomChannel"}" but that's up to
      # the Mesage to format it
      @channel = channel
      @identifier =
        case channel
        when String then { channel: channel }
        when Hash then channel
        else
          raise ActionCableClient::Errors::ChannelNotSpecified, 'channel is invalid'
        end
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
  end
end
