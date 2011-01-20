class FundingAllocationsByTimeReport < ActionController::ReportBase
  set_type_as_show

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/funding_year_and_program_filter'
  end

  def report_label
    "Funding Allocations by date"
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
    filter = params["active_record_base"] || {}
    hash = {}
    hash[:title] = report_label

    start_string = '1/1/' + (filter["funding_year"] || '')
    program_ids= ReportUtility.get_program_ids filter["program_id"]

    start_date = Date.parse(start_string)
    stop_date = start_date.end_of_year()
    years = ReportUtility.get_years start_date, stop_date

    # Some helper queries

    # Funding sources for selected programs
    query = "select id from funding_source_allocations where program_id in (?) AND retired=0 AND deleted_at IS NULL"
    allocation_ids = ReportUtility.extract_ids [query, program_ids]

    # Never include these requests
    always_exclude = "requests.deleted_at IS NULL AND requests.state <> 'rejected'"

    # Series

    # Total Granted
    query = "select sum(amount_recommended) as amount, YEAR(grant_agreement_at) as year, MONTH(grant_agreement_at) as month from requests where #{always_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) group by YEAR(grant_agreement_at), MONTH(grant_agreement_at)"
    total_granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, program_ids], start_date, stop_date, "amount")

    # Granted
    query = "select sum(request_funding_sources.funding_amount) as amount, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{always_exclude} and requests.granted = 1 and requests.grant_agreement_at >= ? and requests.grant_agreement_at <= ? and request_funding_sources.funding_source_allocation_id in (?) group by YEAR(requests.grant_agreement_at), MONTH(requests.grant_agreement_at)"
    granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, allocation_ids], start_date, stop_date, "amount")

    #Pipeline
    query = "select sum(request_funding_sources.funding_amount) as amount from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{always_exclude} and requests.granted = 0 and requests.request_received_at >= ? and requests.request_received_at <= ? and requests.state not in (?) and request_funding_sources.funding_source_allocation_id in (?)"
    res = ReportUtility.single_value_query([query, start_date, stop_date, ReportUtility.pre_pipeline_states, allocation_ids])
    pipeline = Array.new.fill(0, 0, granted.length)
    pipeline << res["amount"].to_i

    #Paid
    # TODO: requires additional columns

    #Budgeted
    query = "SELECT sum(fa.amount) as amount FROM funding_source_allocations fa WHERE fa.retired=0 AND fa.deleted_at IS NULL AND fa.program_id in (?) AND fa.spending_year in (?)"
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

  def report_filter_text controller, index_object, params
    start_date, stop_date = get_date_range params["active_record_base"]
    "#{start_date.strftime('%B %d, %Y')} to #{stop_date.strftime('%B %d, %Y')}"
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

  def report_legend controller, index_object, params
    filter = params["active_record_base"]
    start_date, stop_date = get_date_range filter
    years = ReportUtility.get_years start_date, stop_date
    program_ids= ReportUtility.get_program_ids filter["program_id"]
    always_exclude = "r.deleted_at IS NULL AND r.state <> 'rejected'"
    legend = [["Program", "Grants", "Grant Dollars", "Fips", "Fip Dollars"]]
    categories = ["Total Granted","Granted", "Pipeline", "Budgeted"]
    categories.each do |program|
      query = "select sum(r.amount_recommended) as amount, count(r.id) as count from requests r where #{always_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = ?"
      case program
      when "Total Granted"
        query = "select sum(r.amount_recommended) as amount, count(r.id) as count from requests r where #{always_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
      when "Granted"
        query = "select sum(rs.funding_amount) as amount, count(r.id) as count from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where #{always_exclude} and r.granted = 1 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) and type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
      when "Pipeline"
        query = "select sum(rs.funding_amount) as amount, count(r.id) as count from requests r left join request_funding_sources rs on rs.request_id = r.id left join funding_source_allocations fa on fa.id = rs.funding_source_allocation_id where r.deleted_at IS NULL AND r.state <> 'rejected' and r.granted = 0 and r.grant_agreement_at >= ? and r.grant_agreement_at <= ? and fa.program_id in (?) and type = ? and r.state not in (?)"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest', ReportUtility.pre_pipeline_states]
        fip = [query, start_date, stop_date, program_ids, 'FipRequest', ReportUtility.pre_pipeline_states]
      when "Budgeted"
        query = "SELECT sum(fa.amount) as amount FROM funding_source_allocations fa WHERE fa.retired=0 AND fa.deleted_at IS NULL AND fa.program_id in (?) AND fa.spending_year in (?)"
        grant = [query, program_ids, years]
        fip = [query, program_ids, years]
      end
      grant_result = ReportUtility.single_value_query(grant)
      fip_result = ReportUtility.single_value_query(fip)
      legend << [program, grant_result["count"], number_to_currency(grant_result["amount"] ? grant_result["amount"] : 0 ), fip_result["count"], number_to_currency(fip_result["amount"] ? fip_result["amount"] : 0)]
    end
   legend
  end

end
