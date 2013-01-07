require File.dirname(__FILE__) + '/utils'

def convert_datum array
  items = []
  while 1 < array.size
    tmp = item = array.shift
    score = array.shift.to_f
    items << [item,score]
  end
  unless array.empty?
    puts "you sould set score for label:#{array[0]}"
    exit
  end
  Jubatus::Datum.new([],items)
end

def jubarecommender host, port, argv
  require "jubatus/recommender/client"
  cli = Jubatus::Client::Recommender.new host,port

  exit if common_method(cli, argv)

  command = "nekopero recommender #{argv[0]} "
  result = nil

  case argv[0]
  when "set_config"
    validate_algorighm argv[1],["inverted_index", "minhash", "lsh"], "recommender"
    method = argv[1]
    config_file = argv[2] || "num"
    config = Jubatus::Config_data.new method, load_setting("recommender", config_file).to_json
    puts "setting method:#{method}\nconfig_name:#{config_file}"
    result = set_config(cli, config) ? "failed." : "success."
  when "update_row"
    expected(command,"<id> <label> <score>[<label> <score>...]") if argv[1].nil?
    user = argv[1]
    expected(command,"#{argv[1]} <label> <score>[<label> <score>...]") if argv[2].nil?
    items = convert_datum argv[2..-1]
    puts "update #{user} => #{items.to_tuple[1]}"
    result = cli.update_row("a", user, items) ? "failed." : "success."
  when "complete_row_from_id"
    expected(command,"<id>") if argv[1..-1].empty?
    id = argv[1]
    result = cli.complete_row_from_id("a",id).num_values
  when "complete_row_from_data"
    expected(command, "<label> <score>[<label> <score>...]") if argv[1..-1].empty?
    items = convert_datum argv[1..-1]
    puts "items near #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    result = cli.complete_row_from_data("a", items).num_values.sort{|l,r| r[1] <=> l[1] }
  when "similar_row_from_id"
    expected(command, "<size> <id>") if argv[1].nil?
    size = argv[1] || 1
    expected(command, "#{size} <id>") if argv[2].nil?
    id = argv[2]
    puts "similar_row for #{id} size:#{size.to_i}"
    result = cli.similar_row_from_id("a", id, size.to_i).sort{|l,r| r[1] <=> l[1]}
  when "similar_row_from_data"
    expected(command,"<expect_result_num> <label> <score>[<label> <score>...]") if argv[1..-1].empty?
    size = argv[1] || 1
    expected(command + " #{size}","<label> <score>[<label> <score>...]") if argv[1..-1].empty?
    items = convert_datum argv[2..-1]
    puts "get upto #{size} rows which similar to #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    result = cli.similar_row_from_data("a", items, size.to_i).sort{|l,r| r[1] <=> l[1]}
  when "decode_row"
    expected(command, "<id>") if argv[1].nil?
    result = cli.decode_row("a",argv[1..-1].join(" ")).num_values
  when "get_all_rows"
    result = cli.get_all_rows "a"
  when "l2norm"
    expected(command, "<label> <score>[<label> <score>]") if argv[1..-1].empty?
    items = convert_datum argv[1..-1]
    puts "l2norm for #{items.num_values}"
    result = cli.l2norm "a", items
  when "similarity"
    puts "sorry, similarity command not supported, I expect patch"
    exit
  else
    unknown_command_message cli, argv[0], "recommender"
    exit
  end
  puts "#{argv[0]} result :#{result}"
rescue => e
  p e
  p e.backtrace
end
