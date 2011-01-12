class MonthlyGrantsMoneyReport < ActionController::ReportBase
  include MonthlyGrantsBaseReport
  set_type_as_index
  
  def report_label
    "Grant Dollars By Month"
  end

  def compute_index_plot_data controller, index_object, params, models
    hash = by_month_report models.map(&:id), :sum_amount
    hash[:title] = 'Grant Dollars By Month'
    hash.to_json
  end
end
