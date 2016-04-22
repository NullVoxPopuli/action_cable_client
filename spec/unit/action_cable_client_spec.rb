# frozen_string_literal: true
require 'spec_helper'
require 'ostruct'

describe ActionCableClient::Message do
  context 'with empty WebSocketClient' do
    before(:each) do
      allow(EventMachine::WebSocketClient).to receive(:connect) {}
      @client = ActionCableClient.new('fakeuri')
      allow(@client).to receive(:send_msg) {}
    end

    context '#handle_received_message' do
      context 'is a ping' do
        let(:hash){ {"identifier" => "_ping","type" => "confirm_subscription"} }
        let(:message) { OpenStruct.new(data: hash.to_json ) }
        it 'nothing is yielded' do
          expect{ |b|
            @client.send(:handle_received_message, message, true, &b)
          }.to_not yield_with_args

        end

        it 'yields the ping' do
          expect{ |b|
            @client.send(:handle_received_message, message, false, &b)
          }.to yield_with_args(hash)
        end
      end

      context 'is not a ping' do
        let(:hash) { {"identifier" => "notaping","type" => "message"} }
        let(:message) { OpenStruct.new(data: hash.to_json ) }

        it 'yields whatever' do
          expect{ |b|
            @client.send(:handle_received_message, message, false, &b)
          }.to yield_with_args(hash)
        end
      end

    end

    context '#perform' do
      context 'queueing is enabled' do
        before(:each) do
          allow(@client).to receive(:_queued_send){ true }
        end

        it 'adds to the queue' do
          @client.perform('action', {})
          expect(@client.message_queue.count).to eq 1
        end
      end

      it 'does not add to the queue' do
        @client.perform('action', {})
        expect(@client.message_queue.count).to eq 0
      end

      it 'dispatches the message' do
        expect(@client).to receive(:dispatch_message){}
        @client.perform('action', {})
      end
    end

    context '#dispatch_message' do
      it 'does not send if not subscribed' do
        @client.subscribed = false
        expect(@client).to_not receive(:send_msg)
        @client.send(:dispatch_message, 'action', {})
      end

      it 'calls sends when subscribed' do
        @client.subscribed = true
        expect(@client).to receive(:send_msg){}
        @client.send(:dispatch_message, 'action', {})
      end
    end

    context '#subscribe' do
      it 'sends a message' do
        expect(@client).to receive(:send_msg){}
        @client.send(:subscribe)
      end
    end

    context '#connected' do
      it 'subscribes' do
        # TODO: how do I stub a method chain that takes a block?
        # allow{ |b| @client._websocket_client.callback }.to yield_with_no_args
        # allow(@client).to receive_message_chain(:_websocket_client, :callback).and_yield(Proc.new{})
        # expect(@client).to receive(:subscribe)
        # @client.connected
      end
    end

    context '#deplete_queue' do
      context 'queuing is enabled' do
        before(:each) do
          allow(@client).to receive(:_queued_send){ true }
          @client.subscribed = true
        end
        it 'clears the queue' do
          @client.perform('action', {})

          @client.send(:deplete_queue)
          expect(@client.message_queue.count).to eq 0
        end
      end
    end

    context '#check_for_subscribe_confirmation' do
      it 'is a subscribtion confirmation' do
        msg = { 'identifier' => '_ping', 'type' => 'confirm_subscription' }
        @client.send(:check_for_subscribe_confirmation, msg)
        expect(@client.subscribed?).to eq true
      end
    end

    context '#is_ping?' do
      it 'is a ping' do
        msg = { 'identifier' => '_ping', 'message' => 1_460_201_942 }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq true
      end

      it 'is a ping when it is a confirmation' do
        msg = { 'identifier' => '_ping', 'type' => 'confirm_subscription' }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq true
      end

      it 'is not a ping' do
        msg = { 'identifier' => 'notping', 'message' => 1_460_201_942 }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq false
      end
    end
  end
end
