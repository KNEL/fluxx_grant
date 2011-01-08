# TODO AML: Deprecated
#           I am using this just for testing at the momemt
#   The report data is undoubtedly wrong at this point, but is here merely for a proof of concept
#   Need to respect the filter (I think)
#   Need to remember the last report selected when refreshing the dashboard

class ReportVisualizationsController < ApplicationController
  def self.reports
    [{'Monthly Grants By Program' => 1}]
  end

  def show

    plot = {:library => "jqplot"}

    # Define each report and it's options
    #   library: The javascript graphing engine used to render the report
    #   title: The title of the report
    #   series: Labels for the legend
    #   data: The data for the plot
    #   axes: Settings for the axes (see jqPlot docs)
    case params[:id]
    when "1" then
      plot[:title] = "Monthly Grants By Program"
      plot[:axes] = { :xaxis => { :min => 1, :max => 12, :pad => 1.0, :numberTicks => 12 }, :yaxis => { :numberTicks => 5, :min => 0 }}
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
      # TODO Eventually filter by request ID
      query = "select COUNT(requests.id) as num, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month, requests.program_id as program_id, programs.name as program from requests left join programs on programs.id = requests.program_id where grant_agreement_at IS NOT NULL group by YEAR(grant_agreement_at), MONTH(grant_agreement_at) ORDER BY program"
      req = Request.connection.execute(Request.send(:sanitize_sql, [query]))
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
      end
      #TODO: Less than a year span, limit months!!!!!
      programs.each do |program_id|
        row = []
        (first_year..last_year).each do |year|
          (1..12).each do |month|
            if (program_id == programs.first)
              xaxis << month.to_s + "/" + year.to_s
            end
            row << get_count(data, year, month, program_id)
          end
        end
        plot[:data] << row
      end
    end

    render :inline => plot.to_json
  end
  def index
    render :inline => {}.to_json
  end
end