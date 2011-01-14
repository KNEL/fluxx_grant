module LiquidFilters
  include ActionView::Helpers::NumberHelper
  
  def format_date(date, format = 'full')
    return nil unless date
    date.send(format)
  end
  
  # ex: {{ request_transaction.amount_due | currency: 'Rs. ' }}
  def currency(number, unit='$', delimiter=',', precision=0, format='%u%n')
    return '' if number.blank? || number == 0
    number_to_currency(number, :unit => unit, :delimiter => delimiter, :precision => precision, :format => format)
  end
  
end

Liquid::Template.register_filter(LiquidFilters)