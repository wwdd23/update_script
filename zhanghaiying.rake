res = Supplier.where(:country_name.ne => nil).map(&:country_name).uniq



out = [["司导国家", "服务区域"]]
res.each do |n|

  city = []
  x = Supplier.where(:country_name => n)

  x.each{|m| city.concat(m.services_locations)}

  out << [n, city.uniq]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "可服务国家地区信息", XlsGen.gen(out), "可服务国家信息.xls" ).deliver


## 西南订单
a = Booking.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-11-01"),:sell_name => '卢钢',:status.ne => "退单完成")

out = [["单号", "采购商", "BD", "下单时间", "支付时间", "采购价", "供应价", "利润", "状态", "开始时间", "区域", "开始城市", "类型", "车导", "车型"]]
a.each do |n|
  out << [n.booking_param, n.consumer_company, n.sell_name, n.created_at, n.paid_at, n.total_rmb, n.supplier_total_rmb, n.company_profit, n.status, n.from_date.to_date, n.zone, n.from_city, n.type, n.driver_category, n.car_category]
end

Emailer.send_custom_file(['wudi@haihuilai.com'],  "西南10月订单详情", XlsGen.gen(out), "西南10月订单详情.xls" ).deliver






a = Booking.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"),:status.ne => "退单完成")
a = Booking.where(:paid_at.ne => nil,:status.ne => "退单完成")
Emailer.send_custom_file(['wudi@haihuilai.com'],  "11月订单详情", XlsGen.gen(out), "11月订单详情.xls" ).deliver






list = ["上海申悠旅游咨询有限公司",
"北京金汇通投资基金管理有限公司",
"北京独一之旅国际旅行社有限公司（无二之旅）",
"八大州国际旅行社（上海）有限公司",
"成都途风国际旅行社有限公司",
"成都光大国际旅行社有限责任公司（新旅程）",
"上海驴妈妈兴旅国际旅行社有限公司（出境事业部）",
"上海中国青年旅行社有限公司（上海青旅）",
"世界邦旅行网",
"北京柏舟文化咨询有限公司",]


t = Booking.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-11-01"),:status.nin => [/退/, "预订单失效"]).map_reduce(
     %Q{
          function(){
            var name = this.consumer_company;
            emit({name: name, type: this.type}, {price: this.total_rmb, count: 1, profit: this.company_profit})

          }
       },
       %Q{
          function(key,items){
             var r = {price: 0, count: 0, profit: 0}
             items.forEach(function(item){
                r.price += item.price;
                r.profit += item.profit;
                r.count += item.count;
             })
             return r;
          }

       }
     ).out(:inline => true).to_a




out = [["公司名称", "销售额", "利润", "包车", "包车利润", "接送机", "接送机利润", "精品线路", "精品线路利润",  "销售占比"]]
consumers= t.map{|n| n["_id"]["name"]}.uniq
type = t.map{|n| n["_id"]["type"]}.uniq


consumers.each do |n|

  base = t.select{|m| m["_id"]["name"] == n}
  total_price = base.map{|m| m["value"]["price"]}.reduce(:+).round(2)
  p total_price

  total_profit = base.map{|m| m["value"]["profit"]}.reduce(:+).round(2)

  car_base = base.select{|m| m["_id"]["type"] =~ /车/}
  if car_base.present?
    car_price = car_base.map{|m| m["value"]["price"]}.reduce(:+).round(2)
    car_profit = car_base.map{|m| m["value"]["profit"]}.reduce(:+).round(2)
  else
    car_price = 0
    car_profit = 0 
  end


  air_base = base.select{|m| m["_id"]["type"] =~ /机/ ||  m["_id"]["type"] =~ /站/}
  if air_base.present?
    air_price = air_base.map{|m| m["value"]["price"]}.reduce(:+).round(2)
    air_profit = air_base.map{|m| m["value"]["profit"]}.reduce(:+).round(2)
  else
    air_price = 0
    air_profit = 0 
  end

  line_base = base.select{|m| m["_id"]["type"] == "精品线路"}
  if line_base.present?
    line_price = line_base.map{|m| m["value"]["price"]}.reduce(:+).round(2)
    line_profit = line_base.map{|m| m["value"]["profit"]}.reduce(:+).round(2)
  else
    line_price = 0
    line_profit = 0 
  end

  out << [n,  total_price, total_profit, car_price, car_profit, air_price, air_profit, line_price, line_profit, ""]
end




t.each do |n|
  out << [n["_id"]["name"], n["value"]["price"].round(2), n["value"]["profit"].round(2)]
end





out << ["" , Booking.all.map(&:total_rmb).reduce(:+), Booking.all.map(&:company_profit).reduce(:+)]


Emailer.send_custom_file(['wudi@haihuilai.com'],  "客户收入利润统计_细分", XlsGen.gen(out), "2017客户收入利润统计_细分.xls" ).deliver




