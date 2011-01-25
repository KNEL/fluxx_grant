module FundingAllocationsBaseReport

  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/funding_year_and_program_filter'
  end

  def report_description
    "View current status of each allocation - amount spent, in the pipeline and allocated"
  end

  def temp_table_name
    self.class.name.underscore + "_tmp"
  end

  def get_date_range filter
    start_string = '1/1/' + filter["funding_year"]
    start_date = Date.parse(start_string)
    return start_date, start_date.end_of_year()
  end

  def create_temp_funding_allocations_table name
    queries = ["DROP TABLE IF EXISTS #{name}",
      "CREATE TEMPORARY TABLE #{name} SELECT * FROM funding_source_allocations",
      "UPDATE #{name} tmp LEFT JOIN sub_programs sp ON tmp.sub_program_id = sp.id SET tmp.program_id = sp.program_id WHERE tmp.program_id IS NULL",
      "UPDATE #{name} tmp LEFT JOIN initiatives i ON tmp.initiative_id = i.id LEFT JOIN sub_programs sp ON i.sub_program_id = sp.id SET tmp.program_id = sp.program_id WHERE tmp.program_id IS NULL",
      "UPDATE #{name} tmp LEFT JOIN sub_initiatives si ON tmp.sub_initiative_id = si.id LEFT JOIN initiatives i ON si.initiative_id = i.id LEFT JOIN sub_programs sp ON i.sub_program_id = sp.id SET tmp.program_id = sp.program_id WHERE tmp.program_id IS NULL"]
    queries.each {|sql| Request.connection.execute(Request.send(:sanitize_sql, sql))}
  end

  def drop_temp_funding_allocations_table name
    Request.connection.execute(Request.send(:sanitize_sql, "DROP TABLE IF EXISTS #{name}"))
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
    legend = [{:table => ["Program", "Grants", "Grant Dollars", "Fips", "Fip Dollars"], :filter => ""}]
    categories = ["Total Granted","Granted", "Pipeline", "Budgeted"]
    start_date_string = start_date.strftime('%m/%d/%Y')
    stop_date_string = stop_date.strftime('%m/%d/%Y')
    categories.each do |program|
      card_filter = ""
      case program
      when "Total Granted"
        query = "SELECT SUM(r.amount_recommended) AS amount, count(r.id) AS count FROM requests r WHERE #{always_exclude} AND granted = 1 AND grant_agreement_at >= ? AND grant_agreement_at <= ? AND program_id IN (?) AND type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
      when "Granted"
        query = "SELECT SUM(rs.funding_amount) AS amount, COUNT(DISTINCT r.id) AS count FROM requests r LEFT JOIN request_funding_sources rs ON rs.request_id = r.id LEFT JOIN #{temp_table_name} tmp ON tmp.id = rs.funding_source_allocation_id
          WHERE #{always_exclude} AND r.granted = 1 AND r.grant_agreement_at >= ? AND r.grant_agreement_at <= ? AND tmp.program_id IN (?) AND type = ?"
        grant = [query, start_date, stop_date, program_ids, 'GrantRequest']
        fip = [query, start_date, stop_date, program_ids, 'FipRequest']
        # TODO AML: Get list of filter vars from fluxx
        card_filter ="utf8=%E2%9C%93&q%5Bq%5D=&request%5Bsub_program_id%5D=&request%5Bfilter_type%5D=&request%5Bfilter_state%5D=&request%5Blead_user_ids%5D=&request%5Bcreated_by_id%5D=&request%5Bfunding_source_ids%5D=&request%5Bgreater_amount_recommended%5D=&request%5Blesser_amount_recommended%5D=&request%5Bdate_range_selector%5D=funding_agreement&request%5Brequest_from_date%5D=#{start_date_string}&request%5Brequest_to_date%5D=#{stop_date_string}&request%5Bhas_been_rejected%5D=&request%5Bfavorite_user_ids%5D=&request%5Bsort_attribute%5D=updated_at&request%5Bsort_order%5D=desc&filter-text=Funding+Agreement%2C+1%2F1%2F2010%2C+12%2F31%2F2010%2C+Last+Updated+(Default)%2C+Descending&request[program_id][]=" + program_ids.join("&request[program_id][]=")
      when "Pipeline"
        query = "SELECT SUM(rs.funding_amount) AS amount, COUNT(DISTINCT r.id) AS count FROM requests r LEFT JOIN request_funding_sources rs ON rs.request_id = r.id LEFT JOIN #{temp_table_name} tmp ON tmp.id = rs.funding_source_allocation_id
          WHERE #{always_exclude} AND r.granted = 0 AND tmp.program_id IN (?) AND type = ? AND r.state NOT IN (?)"
        grant = [query, program_ids, 'GrantRequest', ReportUtility.pre_pipeline_states]
        fip = [query, program_ids, 'FipRequest', ReportUtility.pre_pipeline_states]
      when "Budgeted"
        query = "SELECT SUM(tmp.amount) AS amount FROM #{temp_table_name} tmp WHERE tmp.retired=0 AND tmp.deleted_at IS NULL AND tmp.program_id IN (?) AND tmp.spending_year IN (?)"
        grant = [query, program_ids, years]
        fip = [query, program_ids, years]
      end
      grant_result = ReportUtility.single_value_query(grant)
      fip_result = ReportUtility.single_value_query(fip)
      legend << { :table => [program, grant_result["count"], number_to_currency(grant_result["amount"] ? grant_result["amount"] : 0 ), fip_result["count"], number_to_currency(fip_result["amount"] ? fip_result["amount"] : 0)],
                  :filter => card_filter}
    end
    drop_temp_funding_allocations_table temp_table_name
   legend
  end

end
