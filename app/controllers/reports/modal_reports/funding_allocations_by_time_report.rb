class FundingAllocationsByTimeReport < ActionController::ReportBase
  include FundingAllocationsBaseReport
  set_type_as_show

  def report_label
    "Funding Allocations by date"
  end

  def temp_table_name
    "funding_allocations_by_date_temp"
  end

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"] || {}
    hash = {}
    hash[:title] = report_label

    start_string = '1/1/' + (filter["funding_year"] || '')
    program_ids= ReportUtility.get_program_ids filter["program_id"]

    start_date = Date.parse(start_string)
    stop_date = start_date.end_of_year()
    years = ReportUtility.get_years start_date, stop_date

    # Some helper queries
    create_temp_funding_allocations_table temp_table_name

    # Funding sources for selected programs
    query = "SELECT id FROM #{temp_table_name} WHERE program_id IN (?) AND retired=0 AND deleted_at IS NULL"
    allocation_ids = ReportUtility.extract_ids [query, program_ids]

    # Never include these requests
    always_exclude = "r.deleted_at IS NULL AND r.state <> 'rejected'"

    # Series

    # Total Granted
    query = "SELECT SUM(amount_recommended) AS amount, YEAR(grant_agreement_at) AS year, MONTH(grant_agreement_at) AS month FROM requests r WHERE #{always_exclude} AND granted = 1 AND grant_agreement_at >= ?
      AND grant_agreement_at <= ? AND program_id IN (?) GROUP BY YEAR(grant_agreement_at), MONTH(grant_agreement_at)"
    total_granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, program_ids], start_date, stop_date, "amount")

    # Granted
    query = "SELECT SUM(rs.funding_amount) AS amount, YEAR(r.grant_agreement_at) AS year, MONTH(r.grant_agreement_at) AS month FROM requests r
      LEFT JOIN request_funding_sources rs ON rs.request_id = r.id where #{always_exclude} AND r.granted = 1 AND r.grant_agreement_at >= ? AND r.grant_agreement_at <= ? AND rs.funding_source_allocation_id IN (?)
      GROUP BY YEAR(r.grant_agreement_at), MONTH(r.grant_agreement_at)"
    granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, allocation_ids], start_date, stop_date, "amount")

    #Pipeline
    query = "SELECT SUM(rs.funding_amount) AS amount FROM requests r LEFT JOIN request_funding_sources rs ON rs.request_id = r.id WHERE #{always_exclude} AND r.granted = 0
      AND r.request_received_at >= ? AND r.request_received_at <= ? AND r.state NOT IN (?) AND rs.funding_source_allocation_id IN (?)"
    res = ReportUtility.single_value_query([query, start_date, stop_date, ReportUtility.pre_pipeline_states, allocation_ids])
    pipeline = Array.new.fill(0, 0, granted.length)
    pipeline << res["amount"].to_i

    #Paid
    # TODO: requires additional columns

    #Budgeted
    query = "SELECT SUM(amount) AS amount FROM #{temp_table_name} WHERE retired=0 AND deleted_at IS NULL AND program_id IN (?) AND spending_year IN (?)"
    res = ReportUtility.single_value_query([query, program_ids, years])
    budgeted = Array.new.fill(0, 0, granted.length)
    budgeted << res["amount"].to_i

    # Rollups
    xaxis = ReportUtility.get_xaxis(start_date, stop_date)
    xaxis << [xaxis.count + 1, "Total"]
    total_granted << total_granted.inject {|sum, amount| sum + amount }
    granted  << granted.inject {|sum, amount| sum + amount }

    plot = {:library => "jqplot"}

    hash[:title] = "Funding Allocations (date range)"
    hash[:data] = [total_granted, granted, pipeline, budgeted]
    hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :formatString => '$%.2f' }}}
    hash[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Pipeline"}, {:label => "Budgeted"} ]
    hash[:stackSeries] = true;
    hash[:type] = "bar"

    hash.to_json
  end

end
