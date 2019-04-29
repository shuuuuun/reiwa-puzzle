#!/usr/bin/env ruby

# $ ./data/table2csv.rb ./data/gengo.html > ./data/gengo.csv

# https://yhara.jp/2017/08/01/html-table-to-csv
# https://rooter.jp/web-crawling/parse-connected-table/

require 'csv'
require 'nokogiri'

INPUT_FILE = ARGV.first
# puts "INPUT_FILE: #{INPUT_FILE}"

@rowspan_count = {}

def run
  doc = Nokogiri::HTML.parse(File.read(INPUT_FILE))

  doc.search(:table).each do |table|
    csv_txt = CSV.generate(force_quotes: true) do |csv|
      table.search(:tr).each do |tr|
        # csv << tr.search('th, td').map { |tag| tag.text.strip }
        csv << row_to_array(tr)
      end
    end
    puts csv_txt
    puts ''
  end
end

def row_to_array(row)
  cell_nodeset = row.search('th, td')
  return [] if cell_nodeset.nil?
  results = []

  node_index = 0
  until node_index >= cell_nodeset.count && @rowspan_count[results.count].nil?
    unless @rowspan_count[results.count].nil?
      results << @rowspan_count[results.count][:content]
      # results << ''
      index = results.count - 1
      @rowspan_count[index][:remaining_rowspan] -= 1
      if @rowspan_count[index][:remaining_rowspan] == 0
        @rowspan_count.delete(index)
      end
      next
    end
    cell_node = cell_nodeset[node_index]
    content = cell_node.text.strip
    rowspan = cell_node.attribute('rowspan')&.value.to_i
    colspan = cell_node.attribute('colspan')&.value.to_i
    if rowspan > 1
      record(results.count, content, rowspan)
      (colspan - 1).times do
        results << content
        # results << ''
        record(results.count, content, rowspan)
      end
    elsif colspan > 1
      (colspan - 1).times do
        results << content
        # results << ''
      end
    end
    results << content
    node_index += 1
  end
  results
end

def record(index, content, rowspan)
  @rowspan_count[index] = {
    remaining_rowspan: rowspan - 1,
    content: content
  }
end

run
