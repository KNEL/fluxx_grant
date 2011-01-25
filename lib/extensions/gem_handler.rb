class GemHandler
  def self.dependent_gems_block
    (lambda do |params|
      dev_local, cur_dir, gem_versions = params
      gem 'thinking-sphinx', '>=2.0.1', :require => 'thinking_sphinx'
      gem 'writeexcel', '>=0.6.1'
      # per https://gist.github.com/346160
      gem "ghazel-daemons", :require => 'daemons'
      
      # gem "thinking-sphinx", :git => "https://github.com/freelancing-god/thinking-sphinx.git", :branch => "rails3", :require => 'thinking_sphinx'
      if dev_local 
        p "Installing dependent fluxx gems to point to local paths.  Be sure you install fluxx_engine, fluxx_crm and fluxx_grant in the same directory as the reference implementation."
        if File.exist?("#{cur_dir}/../fluxx_engine")
        	gem "fluxx_engine", gem_versions[:fluxx_engine], :path => "../fluxx_engine"
        elsif File.exist?("#{cur_dir}/fluxx_engine")
      	gem "fluxx_engine", gem_versions[:fluxx_engine], :path => "./fluxx_engine"
        end

        if File.exist?("#{cur_dir}/../fluxx_crm")
        	gem "fluxx_crm", gem_versions[:fluxx_crm], :path => "../fluxx_crm"
        elsif File.exist?("#{cur_dir}/fluxx_crm")
      	gem "fluxx_crm", gem_versions[:fluxx_crm], :path => "./fluxx_crm"
        end

        if File.exist?("#{cur_dir}/../fluxx_grant")
        	gem "fluxx_grant", gem_versions[:fluxx_grant], :path => "../fluxx_grant"
        elsif File.exist?("#{cur_dir}/fluxx_grant")
      	  gem "fluxx_grant", gem_versions[:fluxx_grant], :path => "./fluxx_grant"
        end
      else
        p "Installing dependent fluxx gems."
        gem "fluxx_engine", gem_versions[:fluxx_engine]
        gem "fluxx_crm", gem_versions[:fluxx_crm], :require => 'fluxx_crm'
        gem "fluxx_grant", gem_versions[:fluxx_grant], :require => 'fluxx_grant'
      end
    end)
  end
end