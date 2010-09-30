require "formtastic" 
require "active_support" 
require "will_paginate" 
require "action_controller"
require "action_view"
require "fluxx_engine"

p "ESH: loading fluxx_grant"

# Some classes need to be required before or after; put those in these lists
GRANT_EXTENSION_CLASSES_TO_PRELOAD = []
GRANT_EXTENSION_CLASSES_TO_POSTLOAD = []

GRANT_EXTENSION_CLASSES_TO_NOT_AUTOLOAD = GRANT_EXTENSION_CLASSES_TO_PRELOAD + GRANT_EXTENSION_CLASSES_TO_POSTLOAD
GRANT_EXTENSION_CLASSES_TO_PRELOAD.each do |filename|
  require filename
end
Dir.glob("#{File.dirname(__FILE__).to_s}/extensions/**/*.rb").map{|filename| filename.gsub /\.rb$/, ''}.
  reject{|filename| GRANT_EXTENSION_CLASSES_TO_NOT_AUTOLOAD.include?(filename) }.each {|filename| require filename }
GRANT_EXTENSION_CLASSES_TO_POSTLOAD.each do |filename|
  require filename
end

Dir.glob("#{File.dirname(__FILE__).to_s}/fluxx_grant/**/*.rb").each do |fluxx_grant|
  require fluxx_grant.gsub /\.rb$/, ''
end

ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__) + 
"/../app/helpers"

Dir[File.dirname(__FILE__) + "/../app/helpers/**/*_helper.rb"].each do 
|file|
  ActionController::Base.helper "#{File.basename(file,'.rb').camelize}".constantize
end

require 'rails/generators'

class InternalFluxxEnginePublicGenerator < Rails::Generators::Base
  include Rails::Generators::Actions

  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end

  def copy_fluxx_public_files
    public_dir = File.join(File.dirname(__FILE__), '../public')
    directory("#{public_dir}/images", 'public/images/fluxx_grant', :verbose => false)
    directory("#{public_dir}/javascripts", 'public/javascripts/fluxx_grant', :verbose => false)
    directory("#{public_dir}/stylesheets", 'public/stylesheets/fluxx_grant', :verbose => false)
  end
end

InternalFluxxEnginePublicGenerator.new.copy_fluxx_public_files
