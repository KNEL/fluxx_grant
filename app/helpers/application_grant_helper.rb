module ApplicationGrantHelper
  # View ACL  
  def can_current_user_view_users?
    # TODO ESH: check against role
    true
  end

  def can_current_user_view_organizations?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_view_requests?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_view_reports?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_view_transactions?
    # TODO ESH: check against role
    true
  end

  # Edit/Update/Delete ACL  
  def can_current_user_edit_create_users?
    # TODO ESH: check against role
    true
  end

  def can_current_user_edit_create_organizations?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_edit_create_requests?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_edit_create_reports?
    # TODO ESH: check against role
    true
  end
  
  def can_current_user_edit_create_transactions?
    # TODO ESH: check against role
    true
  end
  
  def dollars_format amount
    number_to_currency amount, :precision => 0
  end
  
  def mdy_date_format value
    (value && value.is_a?(Time)) ? value.to_s(:mdy) : value
  end
  
  def show_path_for_model model, options={}
    send("#{model.class.name.tableize.pluralize.downcase}_path", options)
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
    [raw(audit_summary), raw(audit_table)]
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
  
  def render_grant_id request
    if request.is_grant? 
      request.grant_id 
    end
  end

  def render_request_id request
    request.request_id 
  end
  
  def render_grant_or_request_id request
    render_grant_id(request) || render_request_id(request)
  end
  
  def render_text_program_name request, include_fiscal=true
    if request.is_a? FipRequest
      request.fip_title
    else
      org_name = if request.program_organization
        request.program_organization.name
      end
      fiscal_org_name = if include_fiscal && request.fiscal_organization && request.program_organization != request.fiscal_organization
        "a project of #{request.fiscal_organization.name}"
      end
      [org_name, fiscal_org_name].compact.join ', '
    end
  end
  
  def render_program_name request, include_fiscal=true
    if request.is_a? FipRequest
     raw "<span class=\"minimize-detail-pull\">#{request.fip_title}</span> <br />"
    else
      org_name = if request.program_organization
        request.program_organization.name
      end || ''
      fiscal_org_name = if include_fiscal && request.fiscal_organization
        ", a project of #{request.fiscal_organization.name}"
      end || ''
      raw "<span class=\"minimize-detail-pull\">#{org_name + fiscal_org_name}</span> <br />"
    end
  end
  
  def render_grant_amount request, grant_text='Granted'
    if request.is_grant? 
      "#{number_to_currency request.amount_recommended, :precision => 0} #{grant_text}"
    end
  end
  
  def render_request_amount request, request_text
    if request.amount_requested && request.amount_requested != 0 
      "#{request_text} <span class='minimize-detail-pull'>#{number_to_currency request.amount_requested, :precision => 0}</span> <br />"
    end
  end
  
  def render_request_or_grant_amount request, grant_text='Granted', request_text='Request for'
    raw render_grant_amount(request, grant_text) || render_request_amount(request, request_text)
  end

  def plural_by_list list, singular, plural=nil
    count = list ? list.size : 0
    ((count == 1) ? singular : (plural || singular.pluralize))
  end


end