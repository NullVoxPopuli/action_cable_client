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
        let(:hash) { { 'type' => 'ping', 'message' => 1_461_845_503 } }
        let(:message) { OpenStruct.new(data: hash.to_json) }
        it 'nothing is yielded' do
          expect do |b|
            @client.send(:handle_received_message, message, true, &b)
          end.to_not yield_with_args
        end

        it 'yields the ping' do
          expect do |b|
            @client.send(:handle_received_message, message, false, &b)
          end.to yield_with_args(hash)
        end
      end

      context 'is not a ping' do
        let(:hash) { { 'identifier' => 'notaping', 'type' => 'message' } }
        let(:message) { OpenStruct.new(data: hash.to_json) }

        it 'yields whatever' do
          expect do |b|
            @client._subscribed = true
            @client.send(:handle_received_message, message, false, &b)
          end.to yield_with_args(hash)
        end
      end

      context 'empty messages are ignored' do
        let(:message) { OpenStruct.new(data: '') }

        it 'dont yield' do
          expect do |b|
            @client._subscribed = true
            @client.send(:handle_received_message, message, false, &b)
          end.not_to yield_with_args
        end
      end
    end

    context '#perform' do
      it 'does not add to the queue' do
        @client.perform('action', {})
        expect(@client.message_queue.count).to eq 0
      end

      it 'dispatches the message' do
        expect(@client).to receive(:dispatch_message) {}
        @client.perform('action', {})
      end
    end

    context '#dispatch_message' do
      it 'does not send if not subscribed' do
        @client._subscribed = false
        expect(@client).to_not receive(:send_msg)
        @client.send(:dispatch_message, 'action', {})
      end

      it 'calls sends when subscribed' do
        @client._subscribed = true
        expect(@client).to receive(:send_msg) {}
        @client.send(:dispatch_message, 'action', {})
      end
    end

    context '#subscribe' do
      it 'sends a message' do
        expect(@client).to receive(:send_msg) {}
        @client.send(:subscribe)
      end
    end

    context '#subscribed' do
      it 'sets the callback' do
        expect(@client._subscribed_callaback).to eq nil
        @client.subscribed {}
        expect(@client._subscribed_callaback).to_not eq nil
      end

      it 'once the callback is set, receiving a subscription confirmation invokes the callback' do
        callback_called = false
        @client.subscribed do
          callback_called = true
        end

        expect(@client).to receive(:_subscribed_callaback).and_call_original
        message = { 'identifier' => 'ping', 'type' => 'confirm_subscription' }
        @client.send(:check_for_subscribe_confirmation, message)
        expect(callback_called).to eq true
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

    context '#disconnected' do
      it 'sets subscribed to false' do
      end
    end

    context '#check_for_subscribe_confirmation' do
      it 'is a subscribtion confirmation' do
        msg = { 'identifier' => '{"channel":"MeshRelayChannel"}', 'type' => 'confirm_subscription' }
        @client.send(:check_for_subscribe_confirmation, msg)
        expect(@client.subscribed?).to eq true
      end
    end

    context '#is_ping?' do
      it 'is a ping' do
        msg = { 'type' => 'ping', 'message' => 1_461_845_611 }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq true
      end

      it 'is not a ping when it is a confirmation' do
        msg = { 'identifier' => '{"channel":"MeshRelayChannel"}', 'type' => 'confirm_subscription' }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq false
      end

      it 'is not a ping' do
        msg = { 'identifier' => 'notping', 'message' => 1_460_201_942 }
        result = @client.send(:is_ping?, msg)
        expect(result).to eq false
      end
    end
  end
end
