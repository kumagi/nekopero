def setting_file_candidate dirname
  Dir::entries(dirname).map{|x| x.gsub(/(.yaml|.yml|.json)$/,"")}.reject{|x| x.include?(".") || x.include?("~")}
end

require "yaml"
def load_setting dirname, config
  setting_dirpath = File.dirname(__FILE__) + "/#{dirname}"
  begin
    setting = YAML.load_file("#{setting_dirpath}/#{config}.yaml")
  rescue Errno::ENOENT => e
    puts "file #{dirname}/#{config}.yaml not found"
    candidates = setting_file_candidate(setting_dirpath)
    puts "You can specify config within\n#{candidates.join(", ")}"
    puts "Did you mean #{get_candidate_command(config, candidates).join(" or ")} ?"
    exit
  end
end

def expected cmd, wish, candidates=[]
  puts cmd+wish
  puts "select within:\n"+(candidates.map{|c|"  #{c}"}
                             .join("\n")) unless candidates.empty?
  exit
end

def unknown_command_message cli, command, modname
  candidates = (cli.methods - Object.methods.to_a).map{|n|n.to_s}
  puts "unknown method #{command}" unless command.nil?
  puts "expected: nekopero #{modname} <method> [<options>].."
  puts "You can specify method within:\n#{candidates.map{ |c| "  #{c}"}.join "\n"}"
  puts "Did you mean?\n#{get_candidate_command(ARGV[1], candidates.sort).map{ |c| "  #{c}"}.join("\n")}" unless command.nil?
end

def set_config cli, config
  begin
    result = cli.set_config("a",config)
    return false
  rescue MessagePack::RPC::RuntimeError => e
    puts JSON.pretty_generate(JSON.parse(config))
    raise e
  end
  true
end

def validate_algorighm algorithm, candidates, name
  unless candidates.include?(algorithm)
    puts "invalid #{name} algorithm '#{algorithm}', you can select from [#{candidates.join ", "}]"
    puts "Did you mean #{get_candidate_command(algorithm, candidates).join(" or ")}?" unless algorithm.nil?
    exit
  end
end

require 'amatch'
def get_candidate_command command, candidate
  cmd_match = Amatch::Hamming.new(command)
  upper_cmd_match = Amatch::Hamming.new(command.upcase)
  similar_list = (cmd_match.match(candidate).zip(candidate) +
                  upper_cmd_match.match(candidate).zip(candidate))
                  .sort{|l,r|l[0]<=>r[0]}
  similar_list.reject{|s| s[0]!=similar_list[0][0]}.map{|s|s[1]}
end

def common_method cli, argv
  case argv[0]
  when "get_status"
    result = cli.get_status("a")
    puts "get_status: #{result}"
    return true
  when "get_config"
    setting = cli.get_config "a"
    puts "method: #{setting.method}"
    puts "converter: #{JSON.pretty_generate(JSON.parse setting.config)}"
    return true
  when "save"
    if argv[1].nil?
      puts "save name required"
      exit
    end
    result = cli.save "a", argv[1]
    puts "save result: #{result}"
    return true
  when "load"
    if argv[1].nil?
      puts "load name required"
      exit
    end
    result = nil
    begin
      result = cli.load "a", argv[1]
    rescue MessagePack::RPC::RuntimeError => e
      puts "could not load file [#{argv[1]}]"
      exit
    end
    puts "load result:#{result}"
    return true
  end
  false
end
