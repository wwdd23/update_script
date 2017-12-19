info = File.read("/tmp/city.json");nil


json_city = JSON.parse(info);nil
send = [["id", "城市", "国家"]]
json_city["bizCs"].each do |n|
  send << [n["cid"], n["cNm"], n["ctNm"]]
end;nil
File.open('/tmp/ctrip_city.csv', 'w+') {|f| f.write(send)}





# 将csv 转化为hash

ds = CSV.read('data/ctrip_city.csv')

res = []
ds.each do |n|
  res << {
    "city" => n[1],
    "id" => n[0],
    "country" => n[2],
  }
end



data = $mongo_qspider['day_ctrip_casper.js'].find(:created_at => {:$gte => 1.day.ago.to_time,:$lte => Time.now.end_of_day})


count = 1
result = data.to_a; nil

out = [["请求时间", "城市", "服务日期", "服务时间", "行程天数", "行程内容", "车型", "最低价", "最大可乘人数", \
        "行李数", "评分", "价格", "名次", "供应商", "服务"]]

result.each do |n|

  p count = count + 1
  p n
  res = n["data"]
  context = n["context"]

  reg_info = context["text"].match(/refs=(.*)&iscross/)[1]

  log_time = context["time"].to_time
  refs = JSON.parse(reg_info)
  duration = context["text"].match(/duration=(\d+)&refs/)[1] #行程天数
  items_cn = refs["items"].map{|m| m["desctription"]}

  city = res["city_cn"]
  time = res["time"]
  date = res["date"]
  type_cn = res["type_cn"]
  res["data"].each do |m|
    name = m["name"]
    lowprice = m["lowprice"]
    passenger = m["passenger"]
    num = m["num"] #此车型有几个价格
    baggager = m["baggager"]
     
    step = 0
    m["datas"].each do |p| #车型数据
      step = step + 1
      score = p["score"]
      sprice = p["sprice"]
      service = p["service"]
      supply = p["supply"]
      out << [log_time, city, date, time, type_cn, items_cn, name, lowprice, passenger, baggager, score, sprice, step, supply, service]
    end

  end
end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "【携程访问数据抓取】2017-11-03", XlsGen.gen(out), "【携程访问数据抓取】2017-11-03.xls", true ).deliver




x = Booking.where(:paid_at.ne => nil,:consumer_company => /携程/,:status.ne => "退单完成").map{|n| 
  (n.from_date - n.created_at.to_date).to_i
}

count = Booking.where(:paid_at.ne => nil,:consumer_company => /携程/,:status.ne => "退单完成").count



