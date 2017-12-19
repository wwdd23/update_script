info = File.read("/tmp/xhs.json");nil


data = JSON.parse(info);nil

send = [["题目", "名称", "点赞数", "说明", "tags", "高清图片", "小图"]]
data["result"].select{|n| n["tags"].include?("面膜")}.each do |n|
#data["result"].each do |n|
  send << [
    n["title"],
    n["name"],
    n["likes"],
    n["desc"],
    n["tags"],
    n["imageb"],
    n["images"],
  ]
end



