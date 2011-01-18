class GrantAgreementsOverviewReport < ActionController::ReportBase
  set_type_as_show
  set_order 1

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/grant_agreements_overview_filter'
  end
  
  def report_label
    "Grant Agreements Overview"
  end

  def report_description
    "Grant Agreements Overview"
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
    
    sql_clause = ["SELECT requests.type type, programs.name program_name, sub_programs.name sub_program_name, sum(amount_recommended) total_amount_recommended
       FROM requests 
       LEFT OUTER JOIN programs on programs.id = program_id
       LEFT OUTER JOIN sub_programs on sub_programs.id = sub_program_id
       WHERE requests.deleted_at IS NULL AND requests.state <> 'rejected' AND grant_agreement_at > ? AND grant_agreement_at < ? AND granted = 1
       GROUP BY programs.id, sub_programs.id, requests.type
       ORDER BY requests.type desc, programs.name asc, sub_programs.name asc", 
        start_date, end_date]
    models = Request.find_by_sql sql_clause
    
    output = StringIO.new
    workbook = WriteExcel.new(output)
    worksheet = workbook.add_worksheet
    
    # Set up some basic formats:
    bold_format = workbook.add_format()
    bold_format.set_bold()
    total_format = workbook.add_format()
    total_format.set_bold()
    total_format.set_top(1)
    total_format.set_num_format(0x03)
    bold_total_format = workbook.add_format()
    bold_total_format.set_bold()
    bold_total_format.set_top(2)
    bold_total_format.set_num_format(0x03)
    
    double_total_format = workbook.add_format()
    double_total_format.set_bold()
    double_total_format.set_top(6)
    double_total_format.set_num_format(0x03)
    
    # Make the totals column a bit wider
    worksheet.set_column(6, 6, 10)
    
    # Add page summary
    worksheet.write(0, 0, 'The Energy Foundation', bold_format)
    worksheet.write(1, 0, 'Grant Agreements Overview', bold_format)
    worksheet.write(2, 0, "Date Range: " + start_date.mdy + " - " + end_date.mdy)
    worksheet.write(3, 0, "Report Date: " + Time.now.mdy)
    
    # build a data structure which is a hash of type, geo_zone, program, sub_program
    type_hash = {}
    models.each do |model|
      # type
      cur_type = type_hash[model.type]
      cur_type = {} unless cur_type
      type_hash[model.type] = cur_type
      
      # geo_zone
      # cur_geo_zone = cur_type[model.geo_zone_name]
      # cur_geo_zone = {} unless cur_geo_zone
      # cur_type[model.geo_zone_name] = cur_geo_zone
      
      # program
      # cur_program = cur_geo_zone[model.program_name]
      cur_program = cur_type[model.program_name]
      cur_program = {} unless cur_program
      # cur_geo_zone[model.program_name] = cur_program
      cur_type[model.program_name] = cur_program
      
      # sub_program
      cur_program[model.sub_program_name] = model.total_amount_recommended
    end
    
    p "ESH: have type_hash = #{type_hash.inspect}"
    
    row = 4
    total_expense = 0
    type_hash.keys.map do |type_key|
      worksheet.write(row += 1, 2, translate_grant_type(type_key))
      type_total = 0
      cur_type = type_hash[type_key]
      # cur_type.keys.map do |geo_zone_key|
      cur_type.keys.map do |program_key|
        # worksheet.write(row += 1, 3, geo_zone_key)
        # geo_zone = cur_type[geo_zone_key]
        # geo_zone_total = 0
        # geo_zone.keys.map do |program_key|
          worksheet.write(row += 1, 4, program_key)
          # program = geo_zone[program_key]
          program = cur_type[program_key]
          program_total = 0
          program.keys.map do |sub_program_key|
            amount = program[sub_program_key]
            worksheet.write(row += 1, 5, sub_program_key)
            worksheet.write(row, 6, amount.to_i)
            program_total += amount.to_i
          end
          worksheet.write(row += 1, 4, "Total - #{program_key}")
          worksheet.write(row, 6, program_total.to_i, total_format)
          # geo_zone_total += program_total
        # end
        # worksheet.write(row += 1, 3, "Total - #{geo_zone_key}", bold_format)
        # worksheet.write(row, 6, geo_zone_total.to_i, total_format)
        # type_total += geo_zone_total
      end
      worksheet.write(row += 1, 2, "Total - #{translate_grant_type(type_key)}", bold_format)
      worksheet.write(row, 6, type_total.to_i, bold_total_format)
      total_expense += type_total
    end

    worksheet.write(row += 1, 1, "Total Expense")
    worksheet.write(row, 6, total_expense, bold_total_format)
    
    worksheet.write(row += 1, 0, "Net Income", bold_format)
    worksheet.write(row, 6, (total_expense * -1).to_i, double_total_format)

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
