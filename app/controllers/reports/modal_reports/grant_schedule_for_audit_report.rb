class GrantScheduleForAuditReport < ActionController::ReportBase
  set_type_as_show
  set_order 1
  REQUEST_SELECT = 'SELECT (SELECT name FROM programs WHERE id = program_id) program_name, (SELECT name FROM sub_programs WHERE id = sub_program_id) sub_program_name, base_request_id,
         program_organization.name program_org_name,
         program_organization.street_address program_org_street_address, program_organization.street_address2 program_org_street_address2, program_organization.city program_org_city,
         program_org_geo_states.name program_org_state_name, program_org_countries.name program_org_country_name, program_organization.postal_code program_org_postal_code,
         program_organization.url program_org_url,
         fiscal_organization.name fiscal_org_name,
         fiscal_organization.street_address fiscal_org_street_address, fiscal_organization.street_address2 fiscal_org_street_address2, fiscal_organization.city fiscal_org_city,
         fiscal_org_geo_states.name fiscal_org_state_name, fiscal_org_countries.name fiscal_org_country_name, fiscal_organization.postal_code fiscal_org_postal_code,
         fiscal_organization.url fiscal_org_url,
         amount_recommended,
         requests.state,
         (select sum(amount_paid) from request_transactions where request_id = requests.id) amount_transaction,
         IF((select count(*) from request_transactions where request_id = requests.id and amount_paid < 0) = 0, "N", "Y") negative_transactions,
         grant_agreement_at, granted, requests.type, fip_title,
         project_summary
            FROM requests 
            LEFT OUTER JOIN organizations program_organization ON program_organization.id = requests.program_organization_id
            left outer join geo_states as program_org_geo_states on program_org_geo_states.id = program_organization.geo_state_id
            left outer join geo_countries as program_org_countries on program_org_countries.id = program_organization.geo_country_id
            LEFT OUTER JOIN organizations fiscal_organization ON fiscal_organization.id = requests.fiscal_organization_id
            left outer join geo_states as fiscal_org_geo_states on fiscal_org_geo_states.id = fiscal_organization.geo_state_id
            left outer join geo_countries as fiscal_org_countries on fiscal_org_countries.id = fiscal_organization.geo_country_id'
  

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/grant_agreements_overview_filter'
  end
  
  def report_label
    "Grant Schedule For Audit"
  end

  def report_description
    "Grant Schedule For Audit"
  end
  
  def compute_show_document_headers controller, show_object, params
    ['fluxx_' + 'ga_overview' + '_' + Time.now.strftime("%m%d%y") + ".xls", 'application/vnd.ms-excel']
  end
  
  def compute_show_document_data controller, show_object, params
    start_date = if params[:active_record_base][:start_date].blank?
      nil
    else
      Time.parse(params[:active_record_base][:start_date]) rescue nil
    end
    end_date = if params[:active_record_base][:end_date].blank?
      nil
    else
      Time.parse(params[:active_record_base][:end_date]) rescue nil
    end
    
    sql_clause = [REQUEST_SELECT + " WHERE requests.deleted_at IS NULL AND requests.state <> 'rejected' AND grant_agreement_at > ? AND grant_agreement_at < ? AND granted = 1 AND type = 'GrantRequest' ",
              start_date, end_date]
    models = Request.find_by_sql sql_clause

    output = StringIO.new
    workbook = WriteExcel.new(output)
    worksheet = workbook.add_worksheet

    # Set up some basic formats:
    non_wrap_bold_format = workbook.add_format()
    non_wrap_bold_format.set_bold()
    non_wrap_bold_format.set_valign('top')
    bold_format = workbook.add_format()
    bold_format.set_bold()
    bold_format.set_align('center')
    bold_format.set_valign('top')
    bold_format.set_text_wrap()
    header_format = workbook.add_format()
    header_format.set_bold()
    header_format.set_bottom(1)
    header_format.set_align('top')
    header_format.set_text_wrap()
    solid_black_format = workbook.add_format()
    solid_black_format.set_bg_color('black')
    amount_format = workbook.add_format()
    amount_format.set_num_format(0x05)
    amount_format.set_valign('bottom')
    amount_format.set_text_wrap()
    number_format = workbook.add_format()
    number_format.set_num_format(0x01)
    number_format.set_valign('bottom')
    number_format.set_text_wrap()
    date_format = workbook.add_format()
    date_format.set_num_format(15)
    date_format.set_valign('bottom')
    date_format.set_text_wrap()
    text_format = workbook.add_format()
    text_format.set_valign('top')
    text_format.set_text_wrap()

    # Adjust column widths
    worksheet.set_column(0, 0, 15)
    worksheet.set_column(1, 1, 35)
    worksheet.set_column(2, 2, 15)
    worksheet.set_column(3, 3, 35)
    worksheet.set_column(4, 5, 15)
    worksheet.set_column(5, 5, 15)
    worksheet.set_column(6, 6, 15)
    worksheet.set_column(7, 7, 15)
    worksheet.set_column(8, 8, 15)


    # Add page summary
    worksheet.write(0, 0, 'The Energy Foundation', non_wrap_bold_format)
    worksheet.write(1, 0, 'Grant Schedule for Audit report', non_wrap_bold_format)
    worksheet.write(2, 0, "Date Range: " + start_date.mdy + " - " + end_date.mdy)
    worksheet.write(3, 0, "Report Date: " + Time.now.mdy)

    (0..100).each{|i| worksheet.write(5, i, "", solid_black_format)}

    worksheet.set_row(7, 50) # Make the header row taller
    worksheet.write(7, 0, "Grant ID", bold_format)
    worksheet.write(7, 1, "Organization", bold_format)
    worksheet.write(7, 2, "Sector", bold_format)
    worksheet.write(7, 3, "Description", bold_format)
    worksheet.write(7, 4, "Grant Agreement Date", bold_format)
    worksheet.write(7, 5, "State", bold_format)
    worksheet.write(7, 6, "Amount", bold_format)
    worksheet.write(7, 7, "Amount Paid", bold_format)
    worksheet.write(7, 8, "Neg Trans", bold_format)

    row_start = 7
    row = row_start
    models.each do |model|
      worksheet.set_row(row+=1, 50) # Make the detail row taller
      worksheet.write(row, 0, model.display_id, text_format)
      worksheet.write(row, 1, (model.fiscal_org_name ? model.fiscal_org_name : model.program_org_name), text_format)
      worksheet.write(row, 2, model.program_name, text_format)
      worksheet.write(row, 3, model.project_summary, text_format)
      worksheet.write(row, 4, model.grant_agreement_at.to_s(:mdy), date_format)
      worksheet.write(row, 5, model.state, text_format)
      worksheet.write(row, 6, model.amount_recommended, amount_format)
      worksheet.write(row, 7, model.amount_transaction.to_i, amount_format)
      worksheet.write(row, 8, model.negative_transactions, text_format)
    end
    worksheet.write(row+=1,  0, "Total Grant Expenses")
    worksheet.write(row,  6, "=SUM(G#{row_start+2}:G#{row})", amount_format)
    worksheet.write(row,  7, "=SUM(H#{row_start+2}:H#{row})", amount_format)

    workbook.close    
    output.string
  end
  
  def translate_grant_type name
    case name
      when 'GrantRequest'
        'Grants'
      when 'FipRequest'
        'Fips'
    end
  end
  
end
