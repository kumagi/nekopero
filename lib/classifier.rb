require(File.dirname(__FILE__) + '/utils')

def jubaclassifier host, port, argv
  require "jubatus/classifier/client"
  cli = Jubatus::Client::Classifier.new host,port

  exit if common_method(cli, argv)

  command = "usage: > nekopero classifier #{argv[0]} "
  
  case argv[0]
  when "set_config"
    candidates = ["perceptron", "PA1", "PA2", "CW", "AROW", "NHERD"]
    expected(command, "<algorithm>", candidates) if argv[1].nil?
    validate_algorighm argv[1], candidates, "classifier"
    method = argv[1]
    config_file = argv[2] || "space"
    config = Jubatus::Config_data.new method, load_setting("classifier", config_file).to_json
    puts "setting method:#{method}\nconfig_name:#{config_file}"
    result = set_config(cli, config) ? "failed." : "success."
  when "train"
    expected(command, "<label> <data> [<data>...]") if argv[1].nil?
    label = argv[1]
    expected(command, "#{label} <data> [<data>...]") if argv[2].nil?
    value = argv[2..-1].join(' ')
    puts "training #{label} => #{value}"
    result = cli.train("a", [[label, Jubatus::Datum.new([["message",value]],
                                                        [])]]) == true ?
    " failed." : " success."
  when "classify"
    expected "classify argument must be set" if argv[1..-1].empty?
    value = argv[1..-1].join(' ')
    result = "classify #{value}:" +
      (cli.classify("a", [Jubatus::Datum.new([["message", value]],[])]).
       sort{|l,r| r[1]<=>l[1]}.join " ,")
  else
    unknown_command_message cli, argv[0], "classifier"
    exit
  end
  puts "#{argv[0]} result :#{result}"
end
