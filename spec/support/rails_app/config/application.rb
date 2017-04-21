# frozen_string_literal: true
require_relative 'boot'

require 'rails'
# Only testing action cable
[
  # 'active_record/railtie',
  # 'action_controller/railtie',
  # 'action_view/railtie',
  # 'action_mailer/railtie',
  # 'active_job/railtie',
  'action_cable/engine',
  # 'rails/test_unit/railtie',
  # 'sprockets/railtie'
].each do |railtie|
  require railtie
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
