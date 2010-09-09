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
        request.program_organization.display_name
      end
      fiscal_org_name = if include_fiscal && request.fiscal_organization && request.program_organization != request.fiscal_organization
        "a project of #{request.fiscal_organization.display_name}"
      end
      [org_name, fiscal_org_name].compact.join ', '
    end
  end
  
  def render_program_name request, include_fiscal=true
    if request.is_a? FipRequest
     raw "<span class=\"minimize-detail-pull\">#{request.fip_title}</span> <br />"
    else
      org_name = if request.program_organization
        request.program_organization.display_name
      end || ''
      fiscal_org_name = if include_fiscal && request.fiscal_organization
        ", a project of #{request.fiscal_organization.display_name}"
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

  # This method demonstrates the use of the :child_index option to render a
  # form partial for, for instance, client side addition of new nested
  # records.
  #
  # This specific example creates a link which uses javascript to add a new
  # form partial to the DOM.
  #
  #   <% form_for @project do |project_form| -%>
  #     <div id="tasks">
  #       <% project_form.fields_for :tasks do |task_form| %>
  #         <%= render :partial => 'task', :locals => { :f => task_form } %>
  #       <% end %>
  #     </div>
  #   <% end -%>
  # Citation: http://github.com/alloy/complex-form-examples
  def generate_html(form_builder, method, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(method).klass.new
    options[:partial] ||= method.to_s.singularize
    options[:form_builder_local] ||= :f  

    form_builder.fields_for(method, options[:object], :child_index => '{{ record_index }}') do |f|
      render(:partial => options[:partial], :locals => { options[:form_builder_local] => f })
    end
  end

  def generate_template(form_builder, method, options = {})
    escape_carriage_returns(single_quote_html(generate_html(form_builder, method, options)))
  end
  
  def single_quote_html html
    html.gsub '"', "'"
  end

  def escape_carriage_returns html
    html.gsub "\n", '\\n'
  end

end