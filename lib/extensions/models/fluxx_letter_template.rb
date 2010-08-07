module FluxxLetterTemplate
  def self.included(base)
    base.has_many :request_letters
    base.acts_as_audited :except => :delta, :protect => true

    base.insta_search
    base.insta_export
    base.insta_realtime
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    base.add_letter_template_reload_methods
  end

  module ModelClassMethods
    def add_letter_template_reload_methods
      if LetterTemplate.columns.map(&:name).include? 'filename'
        LetterTemplate.all.each do |letter_template|
          method_name, letter_type, template_name = [letter_template.letter_type, letter_template.letter_type, letter_template.filename]

          LetterTemplate.instance_eval %Q{
            def self.reload_#{method_name}
              letter_contents = File.open("#{RAILS_ROOT}/app/views/letter_templates/#{template_name}.html.erb", 'r').read_whole_file
              letter_type = LetterTemplate.find #{letter_template.id}
              letter_type.update_attribute :letter, letter_contents
            end
          }
        end
      end
    end

    def reload_all_letter_templates
      LetterTemplate.all.each do |letter_template|
        self.send "reload_#{letter_template.letter_type}"
      end

    end

    # STOP! use only for dev purposes
    def reload_all_requests_letters
      reload_all_letter_templates

      LetterTemplate.connection.execute 'update request_letters, letter_templates set request_letters.letter = letter_templates.letter where letter_template_id = letter_templates.id'
    end

    def award_category
      'Award'
    end

    def award_letter_templates
      self.find :all, :conditions => {:category => LetterTemplate.award_category}
    end

    def grant_agreement_letter_templates
      self.find :all, :conditions => {:category => LetterTemplate.grant_agreement_category}
    end

    def grant_agreement_category
      'Grant Agreement'
    end

    def letter_categories
      [LetterTemplate.award_category, LetterTemplate.grant_agreement_category]
    end
  end

  module ModelInstanceMethods
  end
end