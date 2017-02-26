# frozen_string_literal: true
class UriParamTestChannel < ApplicationCable::Channel
  def subscribed
    ap params
  end

  def unsubscribed
  end
end
