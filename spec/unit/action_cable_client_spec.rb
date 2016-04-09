require 'spec_helper'

describe ActionCableClient::Message do
  context 'with empty WebSocketClient' do
    before(:each) do
      allow(EventMachine::WebSocketClient).to receive(:connect){}
      @client = ActionCableClient.new('fakeuri')
      allow(@client).to receive(:send_msg){}
    end

    context '#perform' do
      it 'adds to the queue' do
        @client.perform('action', {})
        expect(@client.message_queue.count).to eq 1
      end
    end

    context '#deplete_queue' do
      it 'clears the queue' do
        @client.perform('action', {})

        @client.send(:deplete_queue)
        expect(@client.message_queue.count).to eq 0
      end
    end
  end

end
