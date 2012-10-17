require(File.dirname(__FILE__) + '/utils')

def jubaclassifier host, port, argv
  require "jubatus/classifier/client"
  cli = Jubatus::Client::Classifier.new host,port

  exit if common_method(cli, argv)
  
  case argv[0]
  when "set_config"
    selectable_algorighms = ["perceptron", "PA1", "PA2", "CW", "AROW", "NHERD"]
    if not selectable_algorighms.include?(argv[1])
      puts "invalid classifier algorithm '#{argv[1]}', you can select from [#{selectable_algorighms.join ", "}]"
      puts "Did you mean #{get_candidate_command(argv[1], selectable_algorighms).join(" or ")}?" unless argv[1].nil?
      exit
    end

    method = argv[1]
    config = argv[2] || "space"

    cfg = Jubatus::Config_data.new method, load_setting("classifier", config).to_json

    begin
      puts "setting method:#{method}\nconfig_name:#{config}"
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
  when "train"
    label = argv[1]
    value = argv[2..-1].join(' ')
    puts "training #{label} => #{value}"
    result = cli.train("a", [[label, Jubatus::Datum.new([["message",value]], [])]])
    if result == 1
      puts "success."
    end
  when "classify"
    expected "classify argument must be set" if argv[1..-1].empty?
    value = argv[1..-1].join(' ')
    result = cli.classify("a", [Jubatus::Datum.new([["message", value]],[])])
    puts "classify #{value} => "
    puts "#{value} => #{result[0].sort{|l,r| r[1]<=>l[1]}}"
  else
    candidates = (cli.methods - Object.methods.to_a).map{|n|n.to_s}
    puts "unknown method #{ARGV[1]}" unless ARGV[1].nil?
    puts "expected: nekopero classifier <method> [<options>].."
    puts "You can specify method within #{candidates.join ", "}"
    puts "Did you mean #{get_candidate_command(ARGV[1], candidates).join(" or ")}?" unless ARGV[1].nil?
  end
rescue => e
  p e
  p e.backtrace
end
