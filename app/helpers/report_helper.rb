module ReportHelper
  def self.visualizations
    [{:label => 'Monthly Grants By Program', :value => 1},
     {:label => 'Test Report', :value => 2}]
  end
  def self.data reportID, local_models

    plot = {:library => "jqplot"}
    idString = local_models.map(&:id).join(",")

    # Define each report and it's options
    #   library: The javascript graphing engine used to render the report
    #   title: The title of the report
    #   series: Labels for the legend
    #   data: The data for the plot
    #   axes: Settings for the axes (see jqPlot docs)
    case reportID
    when 1 then
      plot[:title] = "Monthly Grants By Program"
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
      query = "select COUNT(requests.id) as num, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month, requests.program_id as program_id, programs.name as program from requests left join programs on programs.id = requests.program_id where grant_agreement_at IS NOT NULL and requests.id in (?) group by YEAR(grant_agreement_at), MONTH(grant_agreement_at) ORDER BY program"
      req = Request.connection.execute(Request.send(:sanitize_sql, [query, idString]))
      foo = []
      req.each_hash do |row|
        foo << row
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
      end
RAILS_DEFAULT_LOGGER.info  "**************************************************************** " + foo.count.to_s
      #TODO: Less than a year span, limit months!!!!!
      i = 0
      max_grants = 0
      programs.each do |program_id|
        row = []
        (first_year..last_year).each do |year|
          (1..12).each do |month|
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
      axis = []
      xaxis.each_index do |x|
        if x == 0 || x % tick_at == 0
          axis << [x, xaxis[x]]
        end
      end
      axis << [i-1, xaxis[i-1]]
      plot[:axes] = { :xaxis => { :min => 0, :max => i, :ticks => axis }, :yaxis => { :min => 0, :max => max_grants }}
      if plot[:data].count == 0
        plot[:data] << [0]
        plot.delete(:series)
        plot.delete(:axes)
      end
    when 2 then
      # This is a dummy test report
      plot[:title] = "Test Report Two"
      plot[:axes] = { :xaxis => { :min => 1, :max => 12, :pad => 1.0, :numberTicks => 12 }, :yaxis => { :numberTicks => 5, :min => 0 }}
      plot[:seriesDefaults] = { :fill => true, :showMarker => true, :shadow => false }
      plot[:series] = []
      plot[:data] = []
      Program.all.each do |program|
        requests = {}
        row = []
        query = "select COUNT(id) as num, MONTH(grant_agreement_at) as month from requests where program_id = ? and id in (?) group by MONTH(grant_agreement_at)"
        req = Request.connection.execute(Request.send(:sanitize_sql, [query, program.id, idString]))
        req.each_hash{ |res| requests[res["month"].to_i] = res["num"].to_i }
        RAILS_DEFAULT_LOGGER.info  "**************************************************************** " + requests.count.to_s
        if requests.count > 0
          # Make sure we have a value for each month
          (1..12).each do |month|
            num = requests[month] ? requests[month] : 0
            row << num
          end
          plot[:data] << row
          plot[:series] << { :label => program.name }
        end
      end
    end
    plot.to_json
  end
end