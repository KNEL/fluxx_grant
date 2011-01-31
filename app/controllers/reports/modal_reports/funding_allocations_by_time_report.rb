class FundingAllocationsByTimeReport < ActionController::ReportBase
  include FundingAllocationsBaseReport
  set_type_as_show

  def report_label
    "Budget Overview by Date Range"
  end

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"] || {}
    hash = {}
    hash[:title] = report_label
    FundingSourceAllocation.build_temp_table do |temp_table_name|

      start_string = '1/1/' + (filter["funding_year"] || '')
      program_ids= ReportUtility.get_program_ids filter["program_id"]

      start_date = Date.parse(start_string)
      stop_date = start_date.end_of_year()
      years = ReportUtility.get_years start_date, stop_date

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

      #Pipeline
      query = "SELECT SUM(r.amount_requested) AS amount, COUNT(DISTINCT r.id) AS count FROM requests r  WHERE #{always_exclude} AND r.granted = 0 AND r.program_id IN (?) AND r.state NOT IN (?)"
      res = ReportUtility.single_value_query([query, program_ids, ReportUtility.pre_pipeline_states])
      pipeline = Array.new.fill(0, 0, granted.length)
      pipeline << res["amount"].to_i

      #Paid
      query = "select sum(rt.amount_paid) AS amount,  YEAR(r.grant_agreement_at) AS year, MONTH(r.grant_agreement_at) AS month from request_transactions rt, request_transaction_funding_sources rtfs, request_funding_sources rfs, #{temp_table_name} fsa, requests r
        WHERE #{always_exclude} AND rt.state = 'paid' AND rt.id = rtfs.request_transaction_id AND rfs.id = rtfs.request_funding_source_id AND fsa.id = rfs.funding_source_allocation_id AND r.id = rt.request_id
        AND r.grant_agreement_at >= ? AND r.grant_agreement_at <= ? AND fsa.program_id IN (?) GROUP BY YEAR(grant_agreement_at), MONTH(grant_agreement_at)"
      paid = ReportUtility.normalize_month_year_query([query, start_date, stop_date, program_ids], start_date, stop_date, "amount")

      #Budgeted
      query = "SELECT SUM(amount) AS amount FROM #{temp_table_name} WHERE retired=0 AND deleted_at IS NULL AND program_id IN (?) AND spending_year IN (?)"
      res = ReportUtility.single_value_query([query, program_ids, years])
      budgeted = Array.new.fill(0, 0, granted.length)
      budgeted << res["amount"].to_i

      # Rollups
      xaxis = ReportUtility.get_xaxis(start_date, stop_date)
      xaxis << "Year to Date"
      total_granted << total_granted.inject {|sum, amount| sum + amount }
      granted  << granted.inject {|sum, amount| sum + amount }

      plot = {:library => "jqplot"}

      hash[:data] = [total_granted, paid, budgeted, pipeline]
      hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :formatString => "#{I18n.t 'number.currency.format.unit'}%.2f" }}}
      hash[:series] = [ {:label => "Granted"}, {:label => "Paid"}, {:label => "Budgeted"}, {:label => "Pipeline"} ]
      hash[:stackSeries] = false;
      hash[:type] = "bar"
    end
    hash.to_json
  end

end
