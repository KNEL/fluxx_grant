module ReportHelper
  def self.visualizations
    [{:label => 'Monthly Grants By Program', :value => 1},
     {:label => 'Grant Dollars By Month', :value => 2},
      {:label => 'Funding Allocations (date range)', :value => 3}]
  end
  def self.data reportID, local_models
    # Define each report and it's options
    #   library: The javascript graphing engine used to render the report
    #   title: The title of the report
    #   series: Labels for the legend
    #   data: The data for the plot
    #   axes: Settings for the axes (see jqPlot docs)
    case reportID
    when 1 then
      plot = by_month_report reportID, local_models
    when 2 then
      plot = by_month_report reportID, local_models
    when 3 then
      # Simulate user entered filter data
      start_string = '7/4/2010'
      stop_string = '1/1/2011'
      program_ids = (1..23)

      # Array of states that define a request as being in the pipline
      # TODO AML: Need to verify these with Eric
      # TODO AML: Once this report is correctly integrated, need to create an extension point for this
      pipeline_states = ['complete_ierf', 'grant_team_approve', 'po_approve', 'president_approve', 'grant_team_send_back', 'po_send_back', 'president_send_back', 'un_reject', 'become_grant']

      start_date = Date.parse(start_string)
      stop_date = Date.parse(stop_string)

      # Some helper queries

      # Funding sources for selected programs
      query = "select id from funding_source_allocations where program_id in (?)"
      allocation_ids = extract_ids [query, program_ids]

      # Never include these requests
      allways_exclude = "requests.deleted_at IS NULL AND requests.state <> 'rejected'"

      # Series

      # Total Granted
      query = "select sum(amount_recommended) as amount, YEAR(grant_agreement_at) as year, MONTH(grant_agreement_at) as month from requests where #{allways_exclude} and granted = 1 and grant_agreement_at >= ? and grant_agreement_at <= ? and program_id in (?) group by YEAR(grant_agreement_at), MONTH(grant_agreement_at)"
      total_granted = normalize_month_year_query([query, start_date, stop_date, program_ids], start_date, stop_date, "amount")

      # Granted
      query = "select sum(request_funding_sources.funding_amount) as amount, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{allways_exclude} and requests.granted = 1 and requests.grant_agreement_at >= ? and requests.grant_agreement_at <= ? and request_funding_sources.funding_source_allocation_id in (?) group by YEAR(requests.grant_agreement_at), MONTH(requests.grant_agreement_at)"
      granted = normalize_month_year_query([query, start_date, stop_date, allocation_ids], start_date, stop_date, "amount")

      #Pipeline
      query = "select sum(request_funding_sources.funding_amount) as amount, YEAR(requests.request_received_at) as year, MONTH(requests.request_received_at) as month from requests left join request_funding_sources on request_funding_sources.request_id = requests.id where #{allways_exclude} and requests.granted = 0 and requests.request_received_at >= ? and requests.request_received_at <= ? and requests.state in (?) and request_funding_sources.funding_source_allocation_id in (?) group by YEAR(requests.request_received_at), MONTH(requests.request_received_at)"
      pipeline = normalize_month_year_query([query, start_date, stop_date, pipeline_states, allocation_ids], start_date, stop_date, "amount")

      #Paid
      # TODO: requires additional columns

      # Yearly rollups
      #Budgeted
      xaxis = get_xaxis(start_date, stop_date)
      xaxis << [xaxis.count + 1, "Total"]
      total_granted << 1000000
      granted  << 1000000
      pipeline << 1000000




      plot = {:library => "jqplot"}
      plot[:title] = "Funding Allocations (date range)"
      plot[:data] = [total_granted, granted, pipeline]
      plot[:axes] = { :xaxis => {:ticks => xaxis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0}}
      plot[:series] = [ {:label => "Total Granted"}, {:label => "Granted"}, {:label => "Pipeline"} ]
      plot[:stackSeries] = true;
      plot[:type] = "bar"

    end
    plot.to_json
  end

  def self.extract_ids(options)
    req = Request.connection.execute(Request.send(:sanitize_sql, options))
    ids = []
    req.each_hash{ |res| ids << res["id"].to_i }
    return ids
  end

  def self.get_xaxis(start_date, stop_date)
    i = 0
    get_months_and_years(start_date, stop_date).collect{ |date| [i = i + 1, date[0].to_s + "/" + date[1].to_s] }
  end

  # Return query data with values for all months within a range
  def self.normalize_month_year_query(query, start_date, stop_date, result_field)
    req = Request.connection.execute(Request.send(:sanitize_sql, query))
    data = get_months_and_years(start_date, stop_date)
    req.each_hash do |row|
      i = data.index([row["month"].to_i, row["year"].to_i])
      data[i] << row[result_field]
    end
    data.collect { |point| point[2].to_i }
  end

  def self.get_months_and_years(start_date, stop_date)
   (start_date..stop_date).collect { |date| [date.month, date.year] }.uniq
  end
  def self.by_month_report type, local_models
    plot = {:library => "jqplot"}
    plot[:title] = ReportHelper.visualizations[type - 1][:label]
    plot[:seriesDefaults] = { :fill => true, :showMarker => true, :shadow => false }
    plot[:stackSeries] = true;
    plot[:series] = []
    plot[:data] = []

    xaxis = []
    data = []
    legend = []
    programs = []
    data = {}
    first_year = 0
    last_year = 0
    first_month = 0
    last_month = 0
    def self.store_hash data, year, month, program, number
      if !data[year]
        data[year] = {}
      end
      if !data[year][month]
        data[year][month] = {}
      end
      data[year][month][program] = number
    end
    def self.get_count data, year, month, program
      !data[year] || !data[year][month] || !data[year][month][program] ? 0 : data[year][month][program]
    end
    aggregate = ""
    if type == 1
      aggregate = "COUNT(requests.id)"
    else
      aggregate = "SUM(requests.amount_recommended)"
    end
    query = "select #{aggregate} as num, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month, requests.program_id as program_id, programs.name as program from requests left join programs on programs.id = requests.program_id where grant_agreement_at IS NOT NULL and requests.id in (?) group by requests.program_id, YEAR(grant_agreement_at), MONTH(grant_agreement_at) ORDER BY program"
    req = Request.connection.execute(Request.send(:sanitize_sql, [query, local_models.map(&:id)]))
    req.each_hash do |row|
      year = row["year"].to_i
      month = row["month"].to_i
      program_id = row["program_id"].to_i
      store_hash data, year, month, program_id, row["num"].to_i
      if !programs.find_index program_id
        programs << program_id
        plot[:series] << { :label => row["program"] }
      end

      if (year < first_year || first_year == 0)
        first_year = year
      end
      if (year > last_year || last_year == 0)
        last_year = year
      end
      if (month < first_month || first_month == 0)
        first_month = month
      end
      if (month > last_month || last_month == 0)
        last_month = month
      end
    end
    if (first_year != last_year)
      first_month = 1
      last_month = 12
    end
    i = 0
    max_grants = 0
    programs.each do |program_id|
      row = []
      (first_year..last_year).each do |year|
        (first_month..last_month).each do |month|
          if (program_id == programs.first)
            xaxis << month.to_s + "/" + year.to_s
            i = i + 1
          end
          grants = get_count(data, year, month, program_id)
          row << grants
          if (grants > max_grants)
            max_grants = grants
          end
        end
      end
      plot[:data] << row
    end
    num_ticks = 10
    tick_at = xaxis.count / num_ticks
    if tick_at < 1
      tick_at = 1
    end
    axis = []
    xaxis.each_index do |x|
      if x == 0 || x % tick_at == 0
        axis << [x + 1, xaxis[x]]
      end
    end
    plot[:axes] = { :xaxis => { :min => 0, :max => i, :ticks => axis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0}}
    if plot[:data].count == 0
      plot[:data] << [0]
      plot.delete(:series)
      plot.delete(:axes)
    end
    plot
  end
end