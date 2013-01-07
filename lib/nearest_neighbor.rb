require 'pp'
require File.dirname(__FILE__) + '/utils'

def convert_datum array
  items = []
  while 1 < array.size
    item = array.shift
    score = array.shift.to_f
    items << [item,score]
  end
  Jubatus::Datum.new([],items)
end

def jubanearest_neighbor host, port, argv
  require "jubatus/nearest_neighbor/client"
  cli = Jubatus::Client::Nearest_neighbor.new host,port

  exit if common_method(cli, argv)

  command = "nekopero require #{argv[0]} "
  result = nil

  case argv[0]
  when "set_config"
    validate_algorighm argv[1],["euclid_lsh", "minhash", "lsh"], "nearest_neighbor"
    method = argv[1]
    config_file = argv[2] || "num"
    setting = Jubatus::Config_data.new(({"nearest_neighbor:name" => method}),(load_setting("nearest_neighbor", config_file).to_json))
    puts "setting method:#{method}\nconfig_name:#{config_file}"
    result = set_config(cli, setting) ? "failed." : "success."
  when "init_table"
    result = cli.init_table "a"
  when "set_row"
    expected(command,"<id> <label> <score>[<label> <score>...]") if argv[1].nil?
    user = argv[1]
    items = convert_datum argv[2..-1]
    puts "update #{user} => #{items.to_tuple[1]}"
    result = cli.set_row "a", user, items
  when "neighbor_row_from_id"
    expected(command,"<size> <id>") if argv[1..-1].empty?
    size = argv[1] || 1
    id = argv[2]
    puts "neighbor_row for id:#{id} size:#{size}"
    result = cli.neighbor_row_from_id("a", id, size.to_i)
      .sort{|l,r| r[1] <=> l[1] }
  when "neighbor_row_from_data"
    expected(command, "<size> <label> <score>[<label> <score>...]") if argv[1..-1].empty?
    size = argv[1] || 1
    items = convert_datum argv[2..-1]
    puts "items near #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    result = cli.neighbor_row_from_data("a", items, size.to_i)
      .sort{|l,r| r[1] <=> l[1] }
  when "similar_row_from_id"
    expected(command,"<size> <id>") if argv[1..-1].empty?
    size = argv[1] || 1
    id = argv[2]
    puts "similar_row for #{id} size:#{size}"
    result = cli.similar_row_from_id("a", id, size.to_i)
      .sort{|l,r| r[1] <=> l[1] }
  when "similar_row_from_data"
    size = argv[1] || 1
    items = convert_datum argv[2..-1]
    puts "get upto #{size} rows which similar to #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    returned = cli.similar_row_from_data "a", items, size.to_i
    result = returned.sort{|l,r| r[1] <=> l[1] }
    puts "#{result.sort{|l,r| r[1] <=> l[1]}}"
  else
    unknown_command_message cli, argv[0], "nearest_neighbor"
    exit
  end
  puts "#{argv[0]} result :#{result}"
rescue => e
  pp e
  pp e.backtrace
end
