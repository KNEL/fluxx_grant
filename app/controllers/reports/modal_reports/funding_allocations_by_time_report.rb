class FundingAllocationsByTimeReport < ActionController::ReportBase
  set_type_as_show

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/funding_year_and_program_filter'
  end

  def report_label
    "Funding Allocations (date range)"
  end

  def report_description
    "View current status of each allocation - amount spent, in the pipeline and allocated"
  end

  def compute_show_plot_data controller, index_object, params
    filter = params["active_record_base"]
    hash = {}
    hash[:title] = report_label

    start_string = '1/1/' + filter["funding_year"]
    program_ids = filter["program_id"]

    start_date = Date.parse(start_string)
    stop_date = start_date.end_of_year()

    # Some helper queries

    # Funding sources for selected programs
    query = "select id from funding_source_allocations where program_id in (?) AND retired IS NULL AND deleted_at IS NULL"
    allocation_ids = ReportUtility.extract_ids [query, program_ids]

    # Never include these requests
    allways_exclude = "requests.deleted_at IS NULL AND requests.state <> 'rejected'"

    # Series

    # Total Granted
    query = "select sum(amount_recommended) as amount, YEAR(grant_agreement_at) as year, MONTH(grant_agreement_at) as month from requests where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) group by YEAR(grant_agreement_at), MONTH(grant_agreement_at)"
    total_granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, program_ids], start_date, stop_date, "amount")

    # Granted
    query = "select sum(request_funding_sources.funding_amount) as amount, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{allways_exclude} and requests.granted = 1 and requests.grant_agreement_at >= ? and requests.grant_agreement_at <= ? and request_funding_sources.funding_source_allocation_id in (?) group by YEAR(requests.grant_agreement_at), MONTH(requests.grant_agreement_at)"
    granted = ReportUtility.normalize_month_year_query([query, start_date, stop_date, allocation_ids], start_date, stop_date, "amount")

    #Pipeline
    query = "select sum(request_funding_sources.funding_amount) as amount from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{allways_exclude} and requests.granted = 0 and requests.request_received_at >= ? and requests.request_received_at <= ? and requests.state not in (?) and request_funding_sources.funding_source_allocation_id in (?)"
    res = ReportUtility.single_value_query([query, start_date, stop_date, ReportUtility.pre_pipeline_states, allocation_ids])
    pipeline = Array.new.fill(0, 0, granted.length)
    pipeline << res["amount"].to_i

    #Paid
    # TODO: requires additional columns

    #Budgeted
    query = "SELECT sum(fa.amount) as amount FROM funding_source_allocations fa LEFT JOIN funding_sources fs ON fs.id = fa.funding_source_id WHERE fa.retired IS NULL AND fa.deleted_at IS NULL AND fa.program_id in (?) AND fs.start_at <= ? AND fs.end_at >= ?"
    res = ReportUtility.single_value_query([query, program_ids, stop_date, start_date])
    budgeted = Array.new.fill(0, 0, granted.length)
    budgeted << res["amount"].to_i

    # Rollups
    xaxis = ReportUtility.get_xaxis(start_date, stop_date)
    xaxis << [xaxis.count + 1, "Total"]
    total_granted << total_granted.inject {|sum, amount| sum + amount }
    granted  << granted.inject {|sum, amount| sum + amount }

    # Informational
    query = "select count(id) as num, sum(amount_recommended) as amount from requests where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) and type = (?)"
    res = ReportUtility.single_value_query([query, start_date, stop_date, program_ids, "GrantRequest"])
    grants = res["num"]
    grants_total = res["amount"]
    res = ReportUtility.single_value_query([query, start_date, stop_date, program_ids, "FipRequest"])
    fips = res["num"]
    fips_total = res["amount"]

    plot = {:library => "jqplot"}
    hash[:description] = "#{grants} grants totalling $#{grants_total} and #{fips} fips totalling $#{fips_total} from #{start_date.strftime('%m/%d/%Y')} to #{stop_date.strftime('%m/%d/%Y')}."

    hash[:title] = "Funding Allocations (date range)"
    hash[:data] = [total_granted, granted, pipeline, budgeted]
    hash[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :tickOptions => { :showLabel => true }}}
    hash[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Pipeline"}, {:label => "Budgeted"} ]
    hash[:stackSeries] = true;
    hash[:type] = "bar"

    hash.to_json
  end
end
