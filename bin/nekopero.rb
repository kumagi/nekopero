require "json"

module Nekopero
  def setting_file_candidate dirname
    Dir::entries(dirname).map{|x| x.gsub(/.yaml$/,"")}.map{|x| x.gsub(/.json$/,"")}.reject{|x| x.include?(".") || x.include?("~")}
  end

  # TODO: set by argument
  host = "localhost"
  port = 9199

  case ARGV[0]
  when "classifier", "c"
    require "./classifier"
    jubaclassifier host, port, ARGV[1..-1]
  when "recommender", "rec"
    require "./recommender"
    jubarecommender host, port, ARGV[1..-1]
  when "regression", "reg"
    require "jubatus/regresion/client"
  when "stat", "s"
    require "jubatus/stat/client"
  when "graph", "g"
    require "jubatus/graph/client"
  end
end
