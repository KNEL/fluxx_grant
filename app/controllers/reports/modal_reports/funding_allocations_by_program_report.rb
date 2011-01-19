class FundingAllocationsByProgramReport < ActionController::ReportBase
  include ActionView::Helpers::NumberHelper
  set_type_as_show

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/funding_year_and_program_filter'
  end

  def report_label
    "Funding Allocations by program"
  end

  def report_description
    "View current status of each allocation - amount spent, in the pipeline and allocated"
  end

  def get_date_range filter
    start_string = '1/1/' + filter["funding_year"]
    start_date = Date.parse(start_string)
    return start_date, start_date.end_of_year()
  end

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"]
    hash = {}
    hash[:title] = report_label

    program_ids= ReportUtility.get_program_ids filter["program_id"]
    start_date, stop_date = get_date_range filter

    # Never include these requests
    allways_exclude = "r.deleted_at IS NULL AND r.state <> 'rejected'"

    # Selected Programs
    query = "select name, id from programs where id in (?)"
    programs = ReportUtility.query_map_to_array([query, program_ids], program_ids, "id", "name", false)
    xaxis = []
    i = 0
    programs.each { |program| xaxis << [i = i + 1, program] }
    #Total Granted
    query = "select sum(amount_recommended) as amount, program_id from requests r where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) group by program_id"
    total_granted = ReportUtility.query_map_to_array([query, start_date, stop_date, program_ids], program_ids, "program_id", "amount")

    #Granted
    query = "select sum(rs.funding_amount) as amount, fa.program_id as program_id from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where #{allways_exclude} and r.granted = 1 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) group by fa.program_id"
    granted = ReportUtility.query_map_to_array([query, start_date, stop_date, program_ids], program_ids, "program_id", "amount")

    #Paid
    #TODO

    #Budgeted
    query = "SELECT sum(fa.amount) as amount, fa.program_id as program_id FROM funding_source_allocations fa LEFT JOIN funding_sources fs ON fs.id = fa.funding_source_id WHERE fa.retired IS NULL AND fa.deleted_at IS NULL AND fa.program_id in (?) AND fs.start_at <= ? AND fs.end_at >= ? GROUP BY fa.program_id"
    budgeted = ReportUtility.query_map_to_array([query, program_ids, stop_date, start_date], program_ids, "program_id", "amount")

    #Pipeline
    #TODO: Check this
    query = "select sum(rs.funding_amount) as amount, fa.program_id as program_id from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where r.deleted_at IS NULL AND r.state <> 'rejected' and r.granted = 0 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) and r.state not in (?) group by fa.program_id ORDER BY fa.program_id"
    pipeline = ReportUtility.query_map_to_array([query, start_date, stop_date, program_ids, ReportUtility.pre_pipeline_states], program_ids, "program_id", "amount")


    hash = {:library => "jqPlot"}

    hash[:title] = "Funding Allocations by Program"
    hash[:data] = [total_granted, granted, budgeted, pipeline]
    hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :showLabel => true }}}
    hash[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Pipeline"}, {:label => "Budgeted"} ]
    hash[:stackSeries] = true;
    hash[:type] = "bar"

    hash.to_json
  end

  def report_summary controller, index_object, params
    filter = params["active_record_base"]
    start_date, stop_date = get_date_range filter
    program_ids= ReportUtility.get_program_ids filter["program_id"]
    query = "SELECT id FROM requests WHERE deleted_at IS NULL AND state <> 'rejected' and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?)"
    request_ids = ReportUtility.array_query([query, start_date, stop_date, program_ids])
    hash = ReportUtility.get_report_totals request_ids
    "#{hash[:grants]} Grants totaling #{number_to_currency(hash[:grants_total])} and #{hash[:fips]} FIPS totaling #{number_to_currency(hash[:fips_total])}"
  end

  def report_filter_text controller, index_object, params
    start_date, stop_date = get_date_range params["active_record_base"]
    "#{start_date.strftime('%B %d, %Y')} to #{stop_date.strftime('%B %d, %Y')}"
  end

  def report_legend controller, index_object, params
    filter = params["active_record_base"]
    start_date, stop_date = get_date_range filter
    program_ids= ReportUtility.get_program_ids filter["program_id"]
    allways_exclude = "r.deleted_at IS NULL AND r.state <> 'rejected'"
    legend = [["Program", "Grants", "Grant Dollars", "Fips", "Fip Dollars"]]
    categories = ["Total Granted","Granted", "Pipeline", "Budgeted"]
    categories.each do |program|
      query = "select sum(r.amount_recommended) as amount, count(r.id) as count from requests r where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = ?"
      case program
      when "Total Granted"
        query = "select sum(r.amount_recommended) as amount, count(r.id) as count from requests r where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
      when "Granted"
        query = "select sum(rs.funding_amount) as amount, count(r.id) as count from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where #{allways_exclude} and r.granted = 1 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) and type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
      when "Pipeline"
        query = "select sum(rs.funding_amount) as amount, count(r.id) as count from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where r.deleted_at IS NULL AND r.state <> 'rejected' and r.granted = 0 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) and type = ? and r.state not in (?)"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest', ReportUtility.pre_pipeline_states]
        fip = [query, start_date, stop_date, program_ids, 'FipRequest', ReportUtility.pre_pipeline_states]
      when "Budgeted"
        query = "SELECT sum(fa.amount) as amount FROM funding_source_allocations fa LEFT JOIN funding_sources fs ON fs.id = fa.funding_source_id WHERE fa.retired IS NULL AND fa.deleted_at IS NULL AND fa.program_id in (?) AND fs.start_at <= ? AND fs.end_at >= ?"
        grant = [query, program_ids, start_date, stop_date]
        fip = [query, program_ids, start_date, stop_date]
      end
      grant_result = ReportUtility.single_value_query(grant)
      fip_result = ReportUtility.single_value_query(fip)
      legend << [program, grant_result["count"], number_to_currency(grant_result["amount"] ? grant_result["amount"] : 0 ), fip_result["count"], number_to_currency(fip_result["amount"] ? fip_result["amount"] : 0)]
    end
   legend
  end

end
