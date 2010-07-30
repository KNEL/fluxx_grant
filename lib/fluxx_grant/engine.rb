require "rails"
require "action_controller"

module FluxxGrant
  class Engine < Rails::Engine
    rake_tasks do
      load File.expand_path('../../tasks.rb', __FILE__)
    end
  end
end
