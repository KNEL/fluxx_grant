class GemHandler
  def self.dependent_gems_block
    (lambda do |params|
      dev_local, cur_dir, gem_versions = params
      gem 'thinking-sphinx', '>=2.0.1', :require => 'thinking_sphinx'
      gem 'writeexcel', '>=0.6.1'
      
      # gem "thinking-sphinx", :git => "https://github.com/freelancing-god/thinking-sphinx.git", :branch => "rails3", :require => 'thinking_sphinx'
      if dev_local 
        p "Installing dependent fluxx gems to point to local paths.  Be sure you install fluxx_engine, fluxx_crm and fluxx_grant in the same directory as the reference implementation."
        gem_versions.each do |repo_pair|
          repo_name, version = repo_pair
          repo_name_string = repo_name.to_s

          
          if File.exist?("#{cur_dir}/../#{repo_name_string}")
          	gem repo_name_string, version, :path => "../#{repo_name_string}"
          elsif File.exist?("#{cur_dir}/#{repo_name_string}")
        	  gem repo_name_string, version, :path => "./#{repo_name_string}"
          end
        end
      else
        p "Installing dependent fluxx gems."
        gem_versions.each do |repo_pair|
          repo_name, version = repo_pair
          gem repo_name.to_s, version
        end
      end
    end)
  end
end
