# frozen_string_literal: true
class ActionCableClient
  class Message
    attr_reader :_command, :_identifier, :_data

    # @param [String] command - the type of message that this is
    # @param [Hash] identifier - the channel we are subscribed to
    # @param [Hash] data - the data to be sent in this message
    def initialize(command, identifier, data)
      @_command = command
      @_identifier = identifier
      @_data = data
    end

    def to_json
      hash = {
        command: _command,
        identifier: _identifier.to_json
      }

      hash[:data] = _data.to_json if _data.present?

      hash.to_json
    end
  end
end
