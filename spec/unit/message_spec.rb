# frozen_string_literal: true

require 'spec_helper'

describe ActionCableClient::Message do
  it 'sets the attributes' do
    command = 'c',
              identfier = {}
    data = { d: 2 }
    msg = ActionCableClient::Message.new(command, identfier, data)

    expect(msg._command).to eq command
    expect(msg._identifier).to eq identfier
    expect(msg._data).to eq data
  end

  describe '#to_json' do
    non_blank_data = [Object.new, true, 0, 1, 'a', [nil], { nil => 0 },
                      Time.now]
    context 'when data is present' do
      non_blank_data.each do |data|
        it "double the identifier and the data if the value would be #{data.inspect}" do
          command = 'hi'
          identifier = { 'hi': 'there' }

          expected = {
            command: command,
            identifier: identifier.to_json,
            data: data.to_json
          }

          msg = ActionCableClient::Message.new(command, identifier, data)

          expect(expected.to_json).to eq(msg.to_json)
        end
      end
    end

    context 'when data is not prsent' do
      command = 'hi'
      identifier = { 'hi': 'there' }

      blank_data = [nil, false, '', '   ', "  \n\t  \r ", '　', "\u00a0", [],
                    {}]

      blank_data.each do |data|
        it "does not set :data if the value would be #{data.inspect}" do
          expected = {
            command: command,
            identifier: identifier.to_json
          }

          msg = ActionCableClient::Message.new(command, identifier, data)

          expect(expected.to_json).to eq(msg.to_json)
        end
      end
    end
  end
end
