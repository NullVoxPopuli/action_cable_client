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

    context '#check_for_subscribe_confirmation' do
      it 'is a subscribtion confirmation' do
        msg = {"identifier" => "_ping","type" => "confirm_subscription"}
        @client.send(:check_for_subscribe_confirmation, msg)
        expect(@client.subscribed?).to eq true
      end
    end

    context '#is_ping?' do
      it 'is a ping' do
        msg = {"identifier" => "_ping","message" => 1460201942}
        result = @client.send(:is_ping?, msg)
        expect(result).to eq true
      end

      it 'is a ping when it is a confirmation' do
        msg = {"identifier" => "_ping","type" => "confirm_subscription"}
        result = @client.send(:is_ping?, msg)
        expect(result).to eq true
      end

      it 'is not a ping' do
        msg = {"identifier" => "notping","message" => 1460201942}
        result = @client.send(:is_ping?, msg)
        expect(result).to eq false
      end
    end
  end


end
