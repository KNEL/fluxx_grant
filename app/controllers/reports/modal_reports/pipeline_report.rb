class PipelineReport < ActionController::ReportBase
  include PipelineBaseReport
  
  set_type_as_show
  set_order 4
  
  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/pipeline_filter'
  end
  
  def report_label
    'Pipeline report'
  end

  def report_description
    'Pipeline report'
  end
  
  def compute_show_document_headers controller, show_object, params
    ['fluxx_' + 'pipeline' + '_' + Time.now.strftime("%m%d%y") + ".xls", 'application/vnd.ms-excel']
  end
  
  def compute_show_document_data controller, show_object, params
    models, start_date, end_date, spending_year, query_types = load_results params, 'request'
    request_data, sub_programs = process_results models
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
    amount_format.set_num_format("#{I18n.t 'number.currency.format.unit'}#,##0")
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
  
    # Calculate letter combinations for column names for the sake of formulas; A, B, C, .. Z, AB, AC, ... ZZ
    column_letters = ('A'..'Z').to_a
    column_letters = column_letters + column_letters.map {|letter1| column_letters.map {|letter2| letter1 + letter2 } }
    column_letters = column_letters.flatten


    # Adjust column widths
    worksheet.set_column(0, 20+sub_programs.size, 15)
  
  
    # Add page summary
    # worksheet.write(0, 0, 'The Energy Foundation', non_wrap_bold_format)
    worksheet.write(1, 0, 'Pipeline report', non_wrap_bold_format)
    worksheet.write(2, 0, "Date Range: " + start_date.mdy + " - " + end_date.mdy)
    worksheet.write(3, 0, "Report Date: " + Time.now.mdy)

    # Put in a black separator line
    (0..100).each{|i| worksheet.write(5, i, "", solid_black_format)}
  

    worksheet.set_row(7, 50) # Make the header row taller
    column = -1
    worksheet.write(7, column+=1, "Request ID", bold_format)
    worksheet.write(7, column+=1, "Request Amount", bold_format)
    worksheet.write(7, column+=1, "Funding", bold_format)
    sub_programs.each_with_index do |sub_program, i|
      worksheet.write(7, column + 1 + i, (sub_program.program.name + " - " + sub_program.name), bold_format)
    end

    row_start = 7
    row = row_start
    request_ids = request_data.keys.sort
    request_ids.each do |request_id|
      request_map = request_data[request_id] || {}
      program_request_map = request_map[:sub_programs] || {}
      worksheet.set_row(row+=1, 15) # Make the detail row taller
      column = -1
      worksheet.write(row, column+=1, request_map[:entity_name], text_format)
      worksheet.write(row, column+=1, request_map[:amount], amount_format)
      first_letter = column_letters[column+2]
      last_letter = column_letters[sub_programs.size + column + 1]
      worksheet.write(row, column+=1, ("=SUM(" + first_letter + (row+1).to_s + ":" + last_letter + (row+1).to_s + ")"), amount_format)
      sub_programs.each_with_index do |sub_program, i|
        cur_amount = program_request_map[sub_program.id][:funding_amount].to_i rescue ''
        cur_amount = "" if cur_amount == 0
        worksheet.write(row, column + 1 + i, cur_amount, amount_format)
      end
    end
    worksheet.write(row+=1,  0, "Totals")
    # RUBY didn't like the SUM string below for some reason so had to split it up
    # Total of amount recommended
    worksheet.write(row, 1, ("=SUM(" + "B" + (row_start+2).to_s + ":B" + row.to_s + ")"), amount_format)
    # Total of totals of funding
    worksheet.write(row, 2, ("=SUM(" + "C" + (row_start+2).to_s + ":C" + row.to_s + ")"), amount_format)
  
    # Total each funding source by program
    start_char = 3
    sub_programs.each_with_index do |sub_program, i|
      cur_char = column_letters[(start_char+i)]
      worksheet.write(row, 3 + i, "=SUM(#{cur_char}#{row_start+2}:#{cur_char}#{row})", amount_format)
    end

    workbook.close
    output.string
  end
end
