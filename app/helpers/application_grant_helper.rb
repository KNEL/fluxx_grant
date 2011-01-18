module ApplicationGrantHelper
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

  def build_add_card_links
    links = []
    links << "  '#{link_to 'Projects', projects_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_projects]
    links << "  '#{link_to 'Organizations', organizations_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_organizations]
    links << "  '#{link_to 'People', users_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_people]
    links << "  '#{link_to 'Requests', grant_requests_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_requests]
    links << "  '#{link_to "Grants / #{I18n.t(:fip_name).pluralize}", granted_requests_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_grants]
    links << "  '#{link_to 'Grantee Reports', request_reports_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_grantee_reports]
    links << "  '#{link_to 'Transactions', request_transactions_path, :class => 'new-listing'}'" unless FLUXX_CONFIGURATION[:hide_transactions]
    links.join ",\n"
  end

  def build_adminlink
    if current_user.is_admin?
      "'#{link_to 'Admin', admin_card_path(:id => 1), :class => 'new-detail'}',"
    else
      ""
    end
  end

  def build_reportlink
    if current_user.has_view_for_model? RequestReport
      "'#{link_to 'Live Reports', modal_reports_path, :class => 'report-modal'}',"
    else
      ""
    end
  end

  def build_quicklinks
    links = []
    links << "{
      label: 'New Org',
      url: '#{new_organization_path}',
      className: 'new-detail',
      type: 'style-ql-library small'
    }" unless FLUXX_CONFIGURATION[:hide_organizations]
    links << "{
      label: 'New Person',
      url: '#{new_user_path}',
      className: 'new-detail',
      type: 'style-ql-user small'
    }" unless FLUXX_CONFIGURATION[:hide_people]

    request_links = []
    request_links << "  '#{link_to 'New Grant Request', new_grant_request_path, :class => 'new-detail'}'\n" unless FLUXX_CONFIGURATION[:hide_requests]
    request_links << "  '#{link_to 'New ' + I18n.t(:fip_name) + ' Request', new_fip_request_path, :class => 'new-detail'}'\n" unless FLUXX_CONFIGURATION[:hide_requests]

    links << "{
      label: 'New Request',
      url: '#',
      className: 'noop',
      type: 'style-ql-documents small',
      popup: [#{request_links.join ",\n"}
      ]
    }" unless FLUXX_CONFIGURATION[:hide_requests] && FLUXX_CONFIGURATION[:hide_grants]
    links << "{
      label: 'New Project',
      url: '#{new_project_path}',
      className: 'new-detail',
      type: 'style-ql-project small'
    }" unless FLUXX_CONFIGURATION[:hide_projects]
    links.join ",\n"
  end
end