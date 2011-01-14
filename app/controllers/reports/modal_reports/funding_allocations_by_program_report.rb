class FundingAllocationsByProgramReport < ActionController::ReportBase
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

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"]
    hash = {}
    hash[:title] = report_label

    start_string = '1/1/' + filter["funding_year"]
    program_ids= ReportUtility.get_program_ids filter["program_id"]

    start_date = Date.parse(start_string)
    stop_date = start_date.end_of_year()


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

    # Informational
    query = "select count(id) as num, sum(amount_recommended) as amount from requests r where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = (?)"
    res = ReportUtility.single_value_query([query, start_date, stop_date, program_ids, "GrantRequest"])
    grants = res["num"]
    grants_total = res["amount"]
    res = ReportUtility.single_value_query([query, start_date, stop_date, program_ids, "FipRequest"])
    fips = res["num"]
    fips_total = res["amount"]

    hash = {:library => "jqhash"}
    hash[:description] = "#{grants} grants totalling $#{grants_total} and #{fips} fips totalling $#{fips_total} from #{start_date.strftime('%m/%d/%Y')} to #{stop_date.strftime('%m/%d/%Y')}."

    hash[:title] = "Funding Allocations by Program"
    hash[:data] = [total_granted, granted, budgeted, pipeline]
    hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :showLabel => true }}}
    hash[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Pipeline"}, {:label => "Budgeted"} ]
    hash[:stackSeries] = true;
    hash[:type] = "bar"

    hash.to_json
  end
end
