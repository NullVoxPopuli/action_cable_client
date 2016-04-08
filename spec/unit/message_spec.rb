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

  it 'double to_json\'s the identifier and the data' do
    command = 'hi',
              identifier = { "hi": 'there' },
              data = { "data": 'boo' }

    expected = {
      command: command,
      identifier: identifier.to_json,
      data: data.to_json
    }

    msg = ActionCableClient::Message.new(command, identifier, data)

    expected = expected.to_json

    expect(msg.to_json).to eq expected
  end
end
