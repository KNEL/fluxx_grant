# TODO:
#   The report data is undoubtedly wrong at this point, but is here merely for a proof of concept
#   Need to respect the filter (I think)
#   Need to remember the last report selected when refreshing the dashboard

class ReportVisualizationsController < ApplicationController
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
      plot[:title] = year + " Monthly Grants By Program"
      plot[:axes] = { :xaxis => { :min => 1, :max => 12, :pad => 1.0, :numberTicks => 12 }, :yaxis => { :numberTicks => 5, :min => 0 }}
      plot[:seriesDefaults] = { :fill => true, :showMarker => true, :shadow => false }
      series = []
      data = []
      programs = ['Buildings', 'Climate', 'Power', 'Transportation', 'Other']
      program_ids_queried = []
      programs.each do |program|
        if program != 'Other'
          program_id = Program.where(:name => program).first.id
          program_ids_queried << program_id
          condition = "in"
        else
          # The "Other" program is all programs besides the ones queried already
          condition = "not in"
          program_id = program_ids_queried
        end
        series << { :label => program }
        requests = {}
        row = []
        # TODO AML: Should this be filtered on grant_approved_at?
        query = "select COUNT(id) as num, MONTH(created_at) as month from requests where YEAR(created_at) = ? and program_id " + condition + " (?) group by MONTH(created_at)"
        req = Request.connection.execute(Request.send(:sanitize_sql, [query, year, program_id]))
        req.each_hash{ |res| requests[res["month"].to_i] = res["num"].to_i }
        # Make sure we have a value for each month
        (1..12).each do |month|
          num = requests[month] ? requests[month] : 0
          row << num
        end
        data << row
      end
    end
    plot[:data] = data
    plot[:series] = series

    render :inline => plot.to_json
  end
  def index
    render :inline => {}.to_json
  end
end