def setting_file_candidate dirname
  Dir::entries(dirname).map{|x| x.gsub(/.yaml$/,"")}.map{|x| x.gsub(/.json$/,"")}.reject{|x| x.include?(".") || x.include?("~")}
end
