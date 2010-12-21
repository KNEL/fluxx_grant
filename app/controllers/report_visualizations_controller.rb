# TODO:
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
      year = Time.new.year.to_s
      plot[:title] = "#{year} Monthly Grants By Program"
      plot[:axes] = { :xaxis => { :min => 1, :max => 12, :pad => 1.0, :numberTicks => 12 }, :yaxis => { :numberTicks => 5, :min => 0 }}
      plot[:seriesDefaults] = { :fill => true, :showMarker => true, :shadow => false }
      plot[:series] = []
      plot[:data] = []
      Program.all.each do |program|
        requests = {}
        row = []
        # TODO AML: Should this be filtered on grant_approved_at?
        query = "select COUNT(id) as num, MONTH(created_at) as month from requests where YEAR(created_at) = ? and program_id = ? and id in (?) group by MONTH(created_at)"
        req = Request.connection.execute(Request.send(:sanitize_sql, [query, year, program.id, params[:request_ids]]))
        req.each_hash{ |res| requests[res["month"].to_i] = res["num"].to_i }
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

    render :inline => plot.to_json
  end
  def index
    render :inline => {}.to_json
  end
end