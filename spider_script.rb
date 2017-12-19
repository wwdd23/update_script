

n = $mongo_yuspider['air_ctrip_casper.js'].find()


a = []
n.each do |data|

  info = data["data"]

  car_info = info["data"]
  car_info.each{|car| a << car["name"]}

end


a.uniq
"加长5座"
"标准5座"
"标准7座"
"豪华5座"
"10座中巴"
"14座中巴"
"豪华7座"
"8座中巴"


# 临时爬取数据内容

send = [["携程ID", "城市", "日期", "时间", "类型", "车型", "人数", "行李数", "当前车型报价数", "挂牌最低价", "供应商", "供应商价格", "服务内容"]]


$mongo_yuspider['day_ctrip_casper.js'].find({:created_at => {:$gte => Time.parse('2017-03-22')}}).each do |n|
  info = n["data"]
  ctrip_id = info["city"]
  city_cn = info["city_cn"]
  time = info["time"]
  date = info["date"]
  type_cn = info["type_cn"]

  details = info["data"]

  details.each do |d|
    passenger = d["passenger"]
    car = d["name"]
    lowprice = d["lowprice"]
    num = d["num"]
    baggager = d["baggager"]

    supplier_info = d["datas"]

    supplier_info.each do |sup|
      sprice = sup["sprice"] 
      service = sup["service"] 
      supply = sup["supply"] 

      send << [ctrip_id, city_cn, date, time, type_cn, car, lowprice,  passenger, baggager, num, supply, sprice, service ]

    end
  end

end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "携程一日包车基础数据抓取", XlsGen.gen(send), "携程一日包车基础数据抓取.xls" ).deliver




send = [["携程cityId", "机场", "三字码", "目的地", "类型", "执行时间", "车型", "人数", "行李数", "当前车型报价数", "最低价", "供应商", "供应商价", "分值", "服务"],]
$mongo_yuspider['air_ctrip_casper.js'].find({:created_at => {:$gte => Time.parse('2017-03-22')}}).each do |n|

  data = n["data"]

  city_id = data["city"]
  airport_code = data["airport_code"]
  airport_cn = data["airport_cn"]
  address = data["address_cn"]
  date = data["date"]
  type_cn = data["type_cn"]
  
  data["data"].each do |d|
    passenger = d["passenger"]
    car = d["name"]
    lowprice = d["price"]
    num = d["num"]
    baggager = d["baggager"]

    supplier_info = d["datas"]

    supplier_info.each do |sup|
      sprice = sup["sprice"] 
      service = sup["service"] 
      supply = sup["supply"] 
      score = sup["score"] 

      send << [city_id, airport_cn, airport_code, address, type_cn, date, car, passenger, baggager, num, lowprice, supply, sprice, score, service ]

    end
  end
end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "携程接送机抓取数据", XlsGen.gen(send), "20170323携程接送机抓取数据.xls" ).deliver
