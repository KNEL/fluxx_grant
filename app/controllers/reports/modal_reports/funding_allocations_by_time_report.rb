class FundingAllocationsByTimeReport < ActionController::ReportBase
  set_type_as_show
  
  def initialize report_id
    super report_id
    self.filter_template = 'modal_reports/funding_year_and_program_filter'
  end
  
  def report_label
    "Funding Allocations (date range)"
  end

  def compute_show_plot_data controller, index_object, params
    hash = {} #by_month_report models.map(&:id), :sum_amount
    hash[:title] = report_label
    hash.to_json
  end
end
