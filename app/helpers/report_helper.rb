module ReportHelper
  def self.visualizations
    [{:label => 'Monthly Grants By Program', :value => 1},
     {:label => 'Grant Dollars By Month', :value => 2}]
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
    end
    plot.to_json
  end

  def self.by_month_report type, local_models
    plot = {:library => "jqplot"}
    plot[:title] = ReportHelper.visualizations[type - 1][:label]
    plot[:seriesDefaults] = { :fill => true, :showMarker => true, :shadow => false }
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
    query = "select #{aggregate} as num, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month, requests.program_id as program_id, programs.name as program from requests left join programs on programs.id = requests.program_id where grant_agreement_at IS NOT NULL and requests.id in (?) group by YEAR(grant_agreement_at), MONTH(grant_agreement_at) ORDER BY program"
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
    plot[:axes] = { :xaxis => { :min => 0, :max => i, :ticks => axis, :tickOptions => { :angle => -30 }}, :yaxis => { :min => 0, :max => max_grants }}
    if plot[:data].count == 0
      plot[:data] << [0]
      plot.delete(:series)
      plot.delete(:axes)
    end
    plot
  end
end