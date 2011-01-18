class MonthlyGrantsCountReport < ActionController::ReportBase
  include MonthlyGrantsBaseReport
  set_type_as_index
  def report_label
    "Monthly Grants By Program"
  end
  def compute_index_plot_data controller, index_object, params, models
    hash = by_month_report models.map(&:id), :count
    hash[:title] = report_label
    hash.to_json
  end
  def report_summary controller, index_object, params
    return "143 Grants totaling $12,400,300 and 37 FIPS totaling $11,250,900"
  end
  def report_legend controller, index_object, params
    return "legend"
  end

end
