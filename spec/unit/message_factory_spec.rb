require 'spec_helper'

describe ActionCableClient::MessageFactory do


  it 'initializes with a channel name' do
    factory = ActionCableClient::MessageFactory.new('chatroom')

    expect(factory._channel).to eq 'chatroom'
  end

  context '#build_data' do
    it 'returns a constructed hash, given empty message' do
      factory = ActionCableClient::MessageFactory.new('chatroom')
      result = factory.build_data('hi', {})

      expected = { action: 'hi'}
      expect(result).to eq expected
    end

    it 'returns a constructed hash, given a message' do
      factory = ActionCableClient::MessageFactory.new('chatroom')
      result = factory.build_data('hi', { a: 1 })

      expected = { action: 'hi', a: 1 }
      expect(result).to eq expected
    end
  end

  it 'builds the identifier based off the channel name' do
    factory = ActionCableClient::MessageFactory.new('chatroom')

    expected =  { channel: 'chatroom' }
    expect(factory.identifier).to eq expected
  end

  context '#create' do
    it 'creates a message' do
      factory = ActionCableClient::MessageFactory.new('chatroom')

      msg = factory.create('message', 'speak', { data: 1 })
      expect(msg).to be_a_kind_of(ActionCableClient::Message)
    end
  end

end
