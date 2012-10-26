require "ap"
$LOAD_PATH << File.dirname(__FILE__)
require 'utils'

def jubaclassifier host, port, argv
  require "jubatus/classifier/client"
  cli = Jubatus::Client::Classifier.new host,port
  case argv[0]
  when "set_config"
    classifier_algorighms = ["perceptron", "PA1", "PA2", "PA3", "CW", "AROW", "NHERD"]
    if not classifier_algorighms.include?(argv[1])
      puts "invalid classifier algorithm '#{argv[1]}', you can select from [#{classifier_algorighms.join ", "}]"
      exit
    end

    method = argv[1]
    config = argv[2] || "space"
    require "yaml"
    setting = nil
    begin
      setting = YAML.load_file "../lib/classifier/#{config}.yaml"
    rescue Errno::ENOENT => e
      puts "file classifier/#{config}.yaml not found"
      puts "You can specify setting within\n#{setting_file_candidate("classifier").join("\n")}"
      exit
    end

    cfg = Jubatus::Config_data.new method, setting.to_json

    begin
      result = cli.set_config("hoge",cfg)
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
    puts "converter: #{JSON.pretty_generate(JSON.parse setting.config)}"
  when "train"
    label = argv[1]
    value = argv[2..-1].join(' ')
    puts "training #{label} => #{value}"
    result = cli.train("a", [[label, Jubatus::Datum.new([["message",value]], [])]])
    if result == 1
      puts "success."
    end
  when "classify"
    raise "classify argument must be set" if argv[1..-1].empty?
    value = argv[1..-1].join(' ')
    result = cli.classify("a", [Jubatus::Datum.new([["message", value]],[])])
    puts "classify #{value} => "
    ap result
  when "get_status"
    ap cli.get_status("a")
  else
    puts "unknown method #{ARGV[1]}, you must specify method within #{(cli.methods - Object.methods.to_a).map{|n|n.to_s}}"
  end
rescue => e
  ap e
  ap e.backtrace
end
