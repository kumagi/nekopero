require './utils'

def convert_datum array
  items = []
  while 1 < array.size
    item = array.shift
    score = array.shift.to_f
    items << [item,score]
  end
  Jubatus::Datum.new([],items)
end

def jubarecommender host, port, argv
  require "jubatus/recommender/client"
  cli = Jubatus::Client::Recommender.new host,port
  case argv[0]
  when "set_config"
    selectable_algorighms = ["inverted_index", "minhash", "lsh"]
    if not selectable_algorighms.include?(argv[1])
      puts "invalid recommender algorithm '#{argv[1]}', you can select from [#{selectable_algorighms.join ", "}]"
      exit
    end

    method = argv[1]
    config = argv[2] || "num"
    require "yaml"
    setting = nil
    begin
      setting = YAML.load_file "recommender/#{config}.yaml"
    rescue Errno::ENOENT => e
      puts "file recommender/#{config}.yaml not found"
      puts "You can specify setting within\n#{setting_file_candidate("recommender").join("\n")}"
      exit
    end

    cfg = Jubatus::Config_data.new method, setting.to_json

    result = nil
    begin
      result = cli.set_config("a",cfg)
    rescue MessagePack::RPC::RuntimeError => e
      puts JSON.pretty_generate(setting)
      raise e
    end
    if result
      puts "set_config: failed."
    else
      puts "set_config: success."
    end

  when "get_config"
    setting = cli.get_config "a"
    puts "method: #{setting.method}"
    puts "converter: #{JSON.pretty_generate(JSON.parse setting.converter)}"

  when "update_row"
    user = argv[1]
    items = convert_datum argv[2..-1]
    puts "update #{user} => #{items.to_tuple[1]}"
    result = cli.update_row "a", user, items
    if result
      puts "failed"
    else
      puts "success."
    end

  when "complete_row_from_id"
    raise "id argument must be set" if argv[1..-1].empty?
    id = argv[1]
    result = cli.complete_row_from_id "a",id
    puts "#{result.num_values}"
  when "complete_row_from_data"
    raise "datum argument must be set" if argv[1..-1].empty?
    items = convert_datum argv[1..-1]
    puts "items near #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    result = cli.complete_row_from_data "a", items
    puts "result: #{result.num_values.sort{|l,r| r[1] <=> l[1] }}"
  when "similar_row_from_id"
    size = argv[1] || 1
    id = argv[2]
    puts "similar_row for #{id} size:#{size}"
    result = cli.similar_row_from_id "a", id, size.to_i
    puts "result: #{result.sort{|l,r| r[1] <=> l[1]}}"
  when "similar_row_from_data"
    size = argv[1] || 1
    items = convert_datum argv[2..-1]
    puts "get upto #{size} rows which similar to #{items.num_values.sort{|l,r| r[1] <=> l[1]}}"
    result = cli.similar_row_from_data "a", items, size.to_i
    puts "#{result.sort{|l,r| r[1] <=> l[1]}}"
  when "decode_row"
    raise "classify argument must be set" if argv[1..-1].empty?
    puts "result:#{cli.decode_row("a",argv[1..-1].join(" "))}"
  when "get_all_rows"
    result = cli.get_all_rows "a"
    puts "result: #{result}"
  when "get_status"
    result = cli.get_status("a")
    puts "result: #{result}"
  when "save"
    raise "save name required" if argv[1].nil?
    result = cli.save "a", argv[1]
    puts "result: #{result}"
  when "load"
    raise "load name required" if argv[1].nil?
    result = nil
    begin
      result = cli.load "a", argv[1]
    rescue MessagePack::RPC::RuntimeError => e
      puts "could not load file [#{argv[1]}]"
      exit
    end
    puts "result:#{result}"
  else
    puts "unknown method #{ARGV[1]}, you must specify method within #{(cli.methods - Object.methods.to_a).map{|n|n.to_s}}"
  end
rescue => e
  p e
  p e.backtrace
end
