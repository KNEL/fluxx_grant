module ApplicationHelper
  def can_current_user_edit_create_organizations?
    # TODO ESH: override in reference implemention to add check for the correct role
    true
  end
  
  def can_current_user_edit_create_users?
      # TODO ESH: override in reference implemention to add check for the correct role
      true
    end
  
  def link_to_delete label, model, options = {}, use_onclick=true
    options[:method] = :delete
    link_class = options.delete(:link_class)
    refresh_function = (options[:refresh] == :partial ? 'onCompleteRefreshPartial' : 'onCompleteRefresh')
    append_to = (options[:refresh] == :partial ? 'fluxxCardPartial' : 'fluxxCardArea')

    form = raw(form_for(model, :html => options){|f| })
    form = "$('#{raw form}').submit(#{refresh_function}).appendTo($(this).#{append_to}()).submit();return false;"

    raw link_to(label, model, :onclick => (
        use_onclick ? raw("if(confirm('This record will be deleted. Are you sure?')) {#{raw form}}; return false;") : "#{raw form}"), :class => link_class)
  end  
  
  def link_to_update label, model, options = {}
    options[:method] = :put
    link_class = options.delete(:link_class)
    concat link_to(label, model, :onclick => "$(this).next().submit();return false;", :class => link_class)
    raw(form_for(model, :html => options) do |form| 
      yield form
    end)
  end

  def link_to_post label, model, url, options = {}
    options[:method] = :post
    options[:style] = 'display: none'
    link_class = options.delete(:link_class)
    concat link_to(label, url, :onclick => "$(this).next().submit();return false;", :class => link_class)
    raw(form_for(model, :url => url, :html => options) do |form| 
      yield form
    end)
  end
  
  def load_audits model
    model.audits.sort_by{|aud| aud.id * -1}
  end
  
  def build_audit_table_and_summary model, audit
    reflections_by_fk = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.association_foreign_key] = ref if ref
      acc
    end
    reflections_by_name = model.class.reflect_on_all_associations.inject({}) do |acc, ref|
      acc[ref.name.to_s] = ref
      acc
    end
    audit_changes = audit.attributes['changes']
    audit_summary = '<span>'
    audit_summary += " By #{audit.user.full_name}" if audit.user
    audit_summary += " Modified at #{audit.created_at.ampm_time} on #{audit.created_at.full}" if audit.created_at
    audit_table = ''
    if audit_changes && audit_changes.is_a?(Hash)
      audit_table += "<table class='fluxx-card-show-audits-detail'><tr><th class'attribute'>Attribute</th><th class='old'>Was</th><th class='arrow'>&nbsp;</th><th class='new'>Changed To</th></tr>"
      audit_changes.keys.each do |k|
        change = audit_changes[k]
        unless !change.is_a?(Array) || (change.first.blank? && change.second.blank?)
          k_name = k.gsub /_id$/, ''
          old_value, new_value = if reflections_by_fk[k] || reflections_by_name[k_name]
            klass = if reflections_by_fk[k]
              reflections_by_fk[k].class_name.constantize
            else
              reflections_by_name[k_name].class_name.constantize
            end
            old_obj = klass.find(change[0]) rescue nil
            new_obj = klass.find(change[1]) rescue nil
            [(old_obj.respond_to?(:name) ? old_obj.name : old_obj.to_s),
             (new_obj.respond_to?(:name) ? new_obj.name : new_obj.to_s)]
          else
            [change[0], change[1]]
          end
          old_value = if old_value.blank?
            "<span class='empty'>empty</span>" 
          else
            old_value.to_s.humanize
          end
          new_value = if new_value.blank?
            "<span class='empty'>empty</span>"
          else
            new_value.to_s.humanize
          end
          audit_table += "<tr><td class='attribute'>#{k.to_s.humanize}</td><td class='old'>#{old_value}</td><td class='arrow'>&rarr;</td><td class='new'>#{new_value}</td></tr>"
          
        end
      end
      audit_table += "</table>"
    end
    [audit_summary, audit_table]
  end
  
  def build_user_work_contact_details primary_user_org, model
    [
      ['Office Phone:', primary_user_org && primary_user_org.organization ? primary_user_org.organization.phone : nil ],
      ['Office Fax:', primary_user_org && primary_user_org.organization ? primary_user_org.organization.fax : nil ],
      ['Direct Phone:', model.work_phone],
      ['Direct Fax:', model.work_fax],
      ['Email Address:', model.email ],
      ['Personal Phone:', model.personal_phone ],
      ['Personal Mobile:', model.personal_mobile ],
      ['Personal Fax:', model.personal_fax ],
      ['Personal Blog:', model.blog_url ],
      ['Personal Twitter:', model.twitter_url ],
      ['Assistant Name:', model.assistant_name ],
      ['Assistant Phone:', model.assistant_phone ],
      ['Assisant Email:', model.assistant_email ],
    ]
  end
end
