module FluxxGrantTestHelper
  def self.included(base)
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
    eval "class ActionController::Base
      attr_accessor :current_user
    end"
    
    eval "
    class TestHelper
      def self.loaded_meg= val
        @loaded_meg = val
      end

      def self.loaded_meg
        @loaded_meg
      end

      def self.load_megs
        unless TestHelper.loaded_meg
          TestHelper.loaded_meg = true
          setup_grant_multi_element_groups
          setup_grant_org_tax_classes
          setup_grant_fip_types
        end
      end

      def self.clear_blueprint
        @entered = {} unless @entered
        unless @entered[\"#{self.class.name}::#{@method_name}\"]
          @entered[\"#{self.class.name}::#{@method_name}\"] = true

          # It's possible to run out of faker values (such as last name), so if you don't reset your shams you could run out of unique values
          Sham.reset
        end
      end
    end
    "
    
    eval "
    class ActionController::TestCase
      #include Devise::TestHelpers
    end

    # Do not audit log during tests
    module CollectiveIdea #:nodoc:
      module Acts #:nodoc:
        module Audited #:nodoc:
          module InstanceMethods
            private
            def write_audit(attrs)
              # Do nothing during tests
              # self.audits.create attrs if auditing_enabled
            end
          end
        end
      end
    end

    # Swap out the thinking sphinx sphinx interface with actual SQL
    module ThinkingSphinx
      module SearchMethods
        module ClassMethods

          def search_for_ids(*args)
            paged_objects = search *args
            raw_ids = paged_objects.map &:id
            WillPaginate::Collection.create paged_objects.current_page, paged_objects.per_page, paged_objects.total_pages do |pager|
              pager.replace raw_ids
            end
          end

          def search(*args)
            self.paginate(:page => 1)
          end
        end
      end
    end
    
    "
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def add_perms user
      user.has_role! 'listview_all'
      user.has_role! 'view_all'
      user.has_role! 'create_all'
      user.has_role! 'update_all'
      user.has_role! 'delete_all'
    end

    def login_as user
      add_perms user

      @controller.current_user = user
    end

    def login_as_user_with_role role_name, program=@program
      @alternate_user = User.make
      @alternate_user.has_role! role_name, program 
      login_as @alternate_user
      @alternate_user
    end

    def current_user
      @current_user unless @current_user == false
    end

    # Store the given user id in the session.
    def current_user=(new_user)
      @current_user = new_user || false
    end
  end
end