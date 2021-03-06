#!/usr/bin/env ruby

# $ ./data/csv2json.rb ./data/gengo_data.csv > ./gengo-puyo/gengo_data.json

require 'csv'
require 'json'

input_file = ARGV.first
# puts "input_file: #{input_file}"

# 時代,元号名,読み,始期,終期,年数,天皇名,改元理由
headers = %i(era yomi begin_date end_date year_count emperor_name reason)
results = {}
# input = CSV.read(input_file, headers: true)
# input.each do |row|
CSV.foreach(input_file, headers: true) do |row|
  name = row['元号名']
  # 空配列で初期化したhash {era: [], ...}
  results[name] ||= headers.map {|k| [k, []]}.to_h
  results[name][:era] << row['時代']
  results[name][:yomi] << row['読み']
  results[name][:begin_date] << row['始期']
  results[name][:end_date] << row['終期']
  results[name][:year_count] << row['年数']&.gsub(/年/, '')&.to_i
  results[name][:emperor_name] << row['天皇名']
  results[name][:reason] << row['改元理由']

  results[name] = results[name].map {|k,v| [k,v.uniq.compact]}.to_h
end

def parse_date(str)
  # str&.gsub(/\A.*（(.*?)）.*\z/, '\1') || ''
  str&.gsub(/\A.*（(.*?年).*）.*\z/, '\1') || '' # 何月何日 は消す
end

def to_desc(datum)
  "#{datum[:yomi].join("／")}\n" +
  "#{datum[:era].join("／")}\n" +
  "#{parse_date(datum[:begin_date].first)}〜#{parse_date(datum[:end_date].first)}".strip
end

# puts results.to_json
puts results.map {|k,v| v.merge(name: k, description: to_desc(v)) }.to_json
