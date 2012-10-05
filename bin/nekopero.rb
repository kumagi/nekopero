require "json"

module Nekopero
  # TODO: set by argument
  host = "localhost"
  port = 9199
  case ARGV[0]
  when "classifier", "c"
    require "../lib/classifier"
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
  else
    puts "you can select algorithm within classifier, recommender, regression, stat, graph"
  end
end
