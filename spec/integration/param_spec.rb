# frozen_string_literal: true
require 'rails_helper'

describe 'Sending parameters to the server' do
  routes { Rails.application.routes }

  it 'sends during connection' do
    # The plan here is to exit EventMachine once we receive what we need to.
    # We may also want to set some sort of timeout to auto-exit event machine
    EventMachine.run do
      # TODO: how do we know the host of the test server?
      uri = '/cable/?user_name=test_uri_param_on_connect'
      client = ActionCableClient.new(uri, 'UriParamTestChannel')
      client.connected { puts 'success' }
      client.subscribed { puts 'subscribed' }
      client.received do |message|
        puts "msg: #{message}"
      end
    end
  end
end
