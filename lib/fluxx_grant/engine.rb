require "rails"
require "action_controller"
require 'thinking_sphinx/deltas/delayed_delta'

module FluxxGrant
  class Engine < Rails::Engine
    initializer 'fluxx_engine.add_compass_hooks', :after=> :disable_dependency_loading do |app|
      Sass::Plugin.add_template_location "#{File.dirname(__FILE__).to_s}/../../app/stylesheets", "public/stylesheets/compiled/fluxx_grant"
      # Make sure that sphinx indices are loaded properly
      # In thinking sphinx's ThinkingSphinx::Context#add_indexed_models method, I ran rails console and then watched what order the classes are loaded
      Organization rescue nil
      RequestTransaction rescue nil
      RequestReport rescue nil
      Request rescue nil
      User rescue nil
      Project rescue nil
      Request.sphinx_index_names
    end
    
    rake_tasks do
      load File.expand_path('../../tasks.rb', __FILE__)
    end
  end
end
