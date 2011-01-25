class FundingAllocationsByProgramReport < ActionController::ReportBase
  include FundingAllocationsBaseReport
  set_type_as_show

  def report_label
    "Budget Overview by program"
  end

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"]
    hash = {}
    hash[:title] = report_label
    create_temp_funding_allocations_table temp_table_name

    program_ids= ReportUtility.get_program_ids filter["program_id"]
    start_date, stop_date = get_date_range filter
    years = ReportUtility.get_years start_date, stop_date

    # Never include these requests
    always_exclude = "r.deleted_at IS NULL AND r.state <> 'rejected'"

    # Selected Programs
    query = "SELECT name, id FROM programs WHERE id IN (?)"
    programs = ReportUtility.query_map_to_array([query, program_ids], program_ids, "id", "name", false)
    xaxis = []
    i = 0
    programs.each { |program| xaxis << program }
    #Total Granted
    query = "SELECT sum(amount_recommended) as amount, program_id FROM requests r WHERE #{always_exclude} AND granted = 1 AND grant_agreement_at >= ? AND grant_agreement_at <= ? AND program_id IN (?) GROUP BY program_id"
    total_granted = ReportUtility.query_map_to_array([query, start_date, stop_date, program_ids], program_ids, "program_id", "amount")

    #Granted
    query = "SELECT SUM(rs.funding_amount) AS amount, tmp.program_id AS program_id FROM requests r LEFT JOIN request_funding_sources rs ON rs.request_id = r.id
      LEFT JOIN #{temp_table_name} tmp ON tmp.id = rs.funding_source_allocation_id WHERE #{always_exclude} AND r.granted = 1 AND r.grant_agreement_at >= ? AND r.grant_agreement_at <= ? AND tmp.program_id IN (?) GROUP BY tmp.program_id"
    granted = ReportUtility.query_map_to_array([query, start_date, stop_date, program_ids], program_ids, "program_id", "amount")

    #Paid
    #TODO

    #Budgeted
    query = "SELECT SUM(tmp.amount) AS amount, tmp.program_id AS program_id FROM #{temp_table_name} tmp WHERE tmp.retired=0 AND tmp.deleted_at IS NULL AND tmp.program_id IN (?) AND tmp.spending_year IN (?) GROUP BY tmp.program_id"
    budgeted = ReportUtility.query_map_to_array([query, program_ids, years], program_ids, "program_id", "amount")

    #Pipeline
    #TODO: Check this
    query = "SELECT SUM(rs.funding_amount) AS amount, tmp.program_id AS program_id FROM requests r LEFT JOIN request_funding_sources rs ON rs.request_id = r.id
      LEFT JOIN #{temp_table_name} tmp ON tmp.id = rs.funding_source_allocation_id WHERE #{always_exclude} AND r.granted = 0 AND tmp.program_id IN (?) AND r.state NOT IN (?) GROUP BY tmp.program_id"
    pipeline = ReportUtility.query_map_to_array([query, program_ids, ReportUtility.pre_pipeline_states], program_ids, "program_id", "amount")

    hash = {:library => "jqPlot"}

    hash[:title] = "Funding Allocations by Program"
    hash[:data] = [total_granted, granted, budgeted, pipeline]
    hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :formatString => '$%.2f' }}}
    hash[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Budgeted"}, {:label => "Pipeline"} ]
    hash[:stackSeries] = false;
    hash[:type] = "bar"

    hash.to_json
  end

end
