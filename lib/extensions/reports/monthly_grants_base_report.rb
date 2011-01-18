module MonthlyGrantsBaseReport
  include ActionView::Helpers::NumberHelper

  def report_filter_text controller, index_object, params, models
    ReportUtility.get_date_range_string params
  end

  def report_summary controller, index_object, params, models
    hash = ReportUtility.get_report_totals models.map(&:id)
    "#{hash[:grants]} Grants totaling #{number_to_currency(hash[:grants_total])} and #{hash[:fips]} FIPS totaling #{number_to_currency(hash[:fips_total])}"
  end

  def by_month_report request_ids, aggregate_type=:count
    plot = {:library => "jqplot"}
    plot[:title] = 'override this in the calling class...'
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
    if aggregate_type == :sum_amount
      aggregate = "SUM(requests.amount_recommended)"
    else
      aggregate = "COUNT(requests.id)"
    end
    query = "select #{aggregate} as num, YEAR(requests.grant_agreement_at) as year, MONTH(requests.grant_agreement_at) as month, requests.program_id as program_id, programs.name as program from requests left join programs on programs.id = requests.program_id where grant_agreement_at IS NOT NULL and requests.id in (?) group by requests.program_id, YEAR(grant_agreement_at), MONTH(grant_agreement_at) ORDER BY program"
    req = Request.connection.execute(Request.send(:sanitize_sql, [query, request_ids]))
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
    num_ticks = 14
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

  def store_hash data, year, month, program, number
    if !data[year]
      data[year] = {}
    end
    if !data[year][month]
      data[year][month] = {}
    end
    data[year][month][program] = number
  end

  def get_count data, year, month, program
    !data[year] || !data[year][month] || !data[year][month][program] ? 0 : data[year][month][program]
  end
end
