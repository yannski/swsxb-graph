require "csv"
require "erb"
require 'active_support/all'
require 'erb'
require 'pp'

date_regex = "%m/%d/%y"

class ResultRows
  attr_accessor :result_rows

  def initialize(result_rows)
    @result_rows = result_rows
  end

  # Expose private binding() method.
  def get_binding
    binding()
  end
end

years = {
  "2011" => "11/18/11",
  "2012" => "11/16/12",
  "2013" => "11/22/13",
  "2014" => "11/21/14"
}

result_rows = []

years.each{|year, final_date|
  input_filename = "swsxb#{year}.csv"
  output_filename = "swsxb#{year}.html"
  date_and_numbers = {}
  CSV.foreach(input_filename, headers: true){|row|
    date = Time.strptime(row[0], date_regex).to_date.to_s
    number = row[1].to_i
    type = row[2]
    status = row[3]
    if ["PayPal Completed", "PayPal Partially Refunded"].include?(status)
      date_and_numbers[date] ||= 0
      date_and_numbers[date] += number
    end
  }

  end_date = DateTime.strptime(final_date, date_regex).to_date
  begin_date = end_date - 66.days

  accumulator = 0
  result_rows << (begin_date..end_date).map{|date|
    accumulator += date_and_numbers[date.to_s] || 0
    number_of_days_before = (end_date - date).to_i
    val = number_of_days_before == 0 ? "j" : "j - #{number_of_days_before}"
    accumulator
  }
}

result_rows = result_rows.transpose
headers = years.keys
headers.unshift("date")
result_rows.unshift(headers)

template = File.read('template.html.erb')
renderer = ERB.new(template)
output = renderer.result(ResultRows.new(result_rows).get_binding)

File.write("swsxb.html", output)

