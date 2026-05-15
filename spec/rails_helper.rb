# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] = 'test'
ENV['RACK_ENV'] = 'test'

require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
abort("The Rails environment is not running in test mode! Current environment: #{Rails.env}") unless Rails.env.test?

require 'rspec/rails'

Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  config.include AuthHelpers, type: :request
end
