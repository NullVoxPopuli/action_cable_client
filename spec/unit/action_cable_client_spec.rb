# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

describe ActionCableClient do
  context 'with empty WebSocketClient' do
    let!(:websocket_client_class) { class_double(WebSocket::EventMachine::Client).as_stubbed_const }
    let!(:websocket_client) do
      websocket_client = instance_double(WebSocket::EventMachine::Client)

      allow(websocket_client_class).to receive(:connect).and_return websocket_client
      allow(websocket_client).to receive(:onclose) do |&block|
        @websocket_client_onclose_block = block
      end
      allow(websocket_client).to receive(:onmessage)
      allow(websocket_client).to receive(:onerror)
      allow(websocket_client).to receive(:close)

      websocket_client
    end

    let(:host) { 'hostname' }
    let(:port) { 1234 }

    before(:each) do
      @client = ActionCableClient.new("ws://#{host}:#{port}")
      allow(@client).to receive(:send_msg) {}
    end

    context '#handle_received_message' do
      context 'is a ping' do
        let(:hash) { { 'type' => 'ping', 'message' => 1_461_845_503 } }
        let(:message) { hash.to_json }
        it 'nothing is yielded' do
          expect do |b|
            @client.send(:handle_received_message, message, &b)
          end.to_not yield_with_args
        end

        it 'calls _pinged_callback' do
          result = nil

          @client.pinged do |data|
            result = data
          end

          @client.send(:handle_received_message, message)

          expect(result).to eq(hash)
        end
      end

      context 'is not a ping' do
        let(:hash) { { 'identifier' => 'notaping', 'type' => 'message' } }
        let(:message) { hash.to_json }

        it 'yields whatever' do
          expect do |b|
            @client._subscribed = true
            @client.send(:handle_received_message, message, &b)
          end.to yield_with_args(hash)
        end

        it 'does not call _pinged_callback' do
          expect(@client).to_not receive(:_pinged_callback)

          @client.send(:handle_received_message, message)
        end
      end

      context 'is a welcome' do
        let(:hash) { { 'type' => 'welcome' } }
        let(:message) { hash.to_json }

        it 'calls _connected_callback' do
          result = nil

          @client.connected do |data|
            result = data
          end

          @client.send(:handle_received_message, message)

          expect(result).to eq(hash)
        end

        it 'subscribes' do
          expect(@client).to receive(:subscribe)

          @client.send(:handle_received_message, message)
        end
      end

      context 'is a rejection' do
        let(:hash) { { 'type' => 'reject_subscription' } }
        let(:message) { hash.to_json }

        it 'calls _rejected_callback' do
          result = nil

          @client.rejected do |data|
            result = data
          end

          @client.send(:handle_received_message, message)

          expect(result).to eq(hash)
        end
      end

      context 'empty messages are ignored' do
        let(:message) { '' }

        it 'dont yield' do
          expect do |b|
            @client._subscribed = true
            @client.send(:handle_received_message, message, &b)
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
        expect(@client._subscribed_callback).to eq nil
        @client.subscribed {}
        expect(@client._subscribed_callback).to_not eq nil
      end

      it 'once the callback is set, receiving a subscription confirmation invokes the callback' do
        callback_called = false
        @client.subscribed do
          callback_called = true
        end

        expect(@client).to receive(:_subscribed_callback).and_call_original
        message = { 'identifier' => 'ping', 'type' => 'confirm_subscription' }
        @client.send(:check_for_subscribe_confirmation, message)
        expect(callback_called).to eq true
      end
    end

    context '#connected' do
      it 'sets the callback' do
        expect(@client._connected_callback).to eq(nil)

        @client.connected {}

        expect(@client._connected_callback).to_not eq(nil)
      end
    end

    context '#disconnected' do
      it 'sets subscribed to false' do
        @client._subscribed = true

        @websocket_client_onclose_block.call

        expect(@client._subscribed).to be false
      end

      it 'sets the callback' do
        expect(@client._disconnected_callback).to eq(nil)

        @client.disconnected {}

        expect(@client._disconnected_callback).to_not eq(nil)
      end
    end

    context '#pinged' do
      it 'sets the callback' do
        expect(@client._pinged_callback).to eq(nil)

        @client.pinged {}

        expect(@client._pinged_callback).to_not eq(nil)
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

    context '#reconnect!' do
      let(:reconnected_websocket_client) do
        client = instance_double(WebSocket::EventMachine::Client)
        allow(client).to receive(:onclose)
        allow(client).to receive(:onmessage)
        allow(client).to receive(:onerror)
        allow(client).to receive(:close)
        client
      end

      it 'closes the old websocket and connects a new one with the same connection options' do
        headers = { 'Authorization' => 'Bearer token' }
        tls = { cert_chain_file: 'user.crt' }
        client = ActionCableClient.new("ws://#{host}:#{port}", 'RoomChannel', true, headers, tls)

        expect(client._websocket_client).to receive(:close)
        expect(websocket_client_class).to receive(:connect).with(
          uri: "ws://#{host}:#{port}",
          headers: headers,
          tls: tls
        ).and_return(reconnected_websocket_client)

        client.reconnect!

        expect(client._websocket_client).to eq(reconnected_websocket_client)
        expect(client.subscribed?).to eq false
      end

      it 'reattaches the received callback to the new websocket' do
        received_messages = []
        connected_messages = []

        @client.received do |message|
          received_messages << message
        end
        @client.connected do |message|
          connected_messages << message
        end

        allow(reconnected_websocket_client).to receive(:onmessage) do |&block|
          @reconnected_onmessage_block = block
        end
        expect(websocket_client_class).to receive(:connect).and_return(reconnected_websocket_client)

        @client.reconnect!

        message = { 'type' => 'welcome' }
        @reconnected_onmessage_block.call(message.to_json, nil)

        expect(connected_messages).to eq([message])
        expect(received_messages).to eq([])
      end

      it 'ignores stale callbacks from the old websocket after reconnecting' do
        connected_messages = []

        @client.received {}
        @client.connected do |message|
          connected_messages << message
        end

        allow(websocket_client).to receive(:onmessage) do |&block|
          @old_onmessage_block = block
        end
        @client.received {}

        expect(websocket_client_class).to receive(:connect).and_return(reconnected_websocket_client)

        @client.reconnect!

        @client._subscribed = true
        @websocket_client_onclose_block.call
        @old_onmessage_block.call({ 'type' => 'welcome' }.to_json, nil)

        expect(@client.subscribed?).to eq true
        expect(connected_messages).to eq([])
      end

      it 'reattaches the errored callback to the new websocket' do
        errors = []

        @client.errored do |error|
          errors << error
        end

        allow(reconnected_websocket_client).to receive(:onerror) do |&block|
          @reconnected_onerror_block = block
        end
        expect(websocket_client_class).to receive(:connect).and_return(reconnected_websocket_client)

        @client.reconnect!

        @reconnected_onerror_block.call('connection failed')

        expect(errors).to eq(['connection failed'])
      end
    end
  end
end
