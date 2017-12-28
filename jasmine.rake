# 历史接送人数汇总
Booking.without_drawback.where(:paid_at => Time.parse("2017-01-01")..Time.now).map(&:people_num).reduce(:+)


# 细分接送机 包车统计
#
#
#

base = Booking.without_drawback.where(:paid_at => Time.parse("2017-01-01")..Time.now).map_reduce(
  %Q{
  function(){
    var key = this.type
    emit(key, {num: this.people_num})

  }

  },
  %Q{
  function(key, items){
    var r  = {num: 0}
    items.forEach(function(item) {
      r.num += item.num
    });
  return r;
  }
}).out(:inline => true).to_a

out = [["类型", "人数"]]
base.each do |n|
  out << [n["_id"], n["value"]["num"].to_i]
end
a = out.clone

a.shift

all_count = a.map{|n| n[1]}.reduce(:+).to_i

out << ["合计", all_count]


Emailer.send_custom_file(['wudi@haihuilai.com'],  "1-6月总服务出行人数统计", XlsGen.gen(out), "1~6月总服务出行人数统计.xls" ).deliver_now



## 每月订单信息数据



out =[["单号", "下单时间",  "支付时间", "订单状态", "采购商", "供应商", "出发国家", "出发城市", "出行日期", "结束时间", "类型", "采购金额", "采购本币金额", "供应金额", "供应本币金额",  "币种",  "汇率", "利润"]]
base_booking.where(:consumer_company.nin => [/测试/]).each do |n|
  currency_name = n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:currency).try(:name_cn)
  out << [n.booking_param, n.created_at.to_date, n.paid_at.to_date, n.status, n.consumer_company, n.supplier_name, n.from_country, n.from_city, n.from_date.to_date,  n.to_date.to_date, n.type,
          n.total_rmb, n.total_original_currency, n.supplier_total_rmb, n.supplier_locale_price, currency_name, n.conversion_rate, n.company_profit]
end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "12月历史订单基础信息", XlsGen.gen(out), "12月历史订单基础信息.xls" ).deliver_now



##  月信息统计 real_order info 
# ota  携程  "携程API采购账号" 
# API其他 => ["伙力专车（API）", "上海久柏易游信息技术有限公司（900游API）", "首汽约车API",  "上海申悠旅游咨询有限公司API"]
#
# Top20 采购商

base_booking = Booking.real_order.where(:paid_at.ne => nil, :to_date => Time.parse("2017-12-01")..Time.parse("2018-01-01"), :status => "订单完成")
res = base_booking.map_reduce(
  %Q{
  function(){
    var consumer = this.consumer_company
    var price = this.total_rmb
    var type = this.type
    emit({consumer: consumer, type: type, day_count: this.day_count, type: type}, {price: price, count: 1 })

  }

  },
  %Q{
  function(key, items){
    var r  = {price: 0, count: 0}
    items.forEach(function(item) {
      r.price += item.price
      r.count += item.count
    });
  return r;
  }
}).out(:inline => true).to_a

# 销售金额统计
all_company = res.map{|n| n["_id"]["consumer"]}.uniq;nil

s = []
#all_company.delete_if{|n| n == ota_list.first}
ota_list = ["携程API采购账号"]
api_list =  ["伙力专车（API）", "上海久柏易游信息技术有限公司（900游API）", "首汽约车API",  "上海申悠旅游咨询有限公司API"]
all_company.each do |n|
  next if ota_list.include?(n)
  next if api_list.include?(n)
  r = res.select{|m| m["_id"]["consumer"] == n}
  total_price = r.map{|m| m["value"]["price"]}.reduce(:+)
  s << [n, total_price]
end


api_info = []
api_list.each do |n|
  api_info.concat(res.select{|m| m["_id"]["consumer"] == n})
end
total_api_price = api_info.map{|n| n["value"]["price"]}.reduce(:+).to_f.round(2)
total_api_count = api_info.map{|n| n["value"]["count"]}.reduce(:+).to_i

ota_info = []
ota_list.each do |n|
  ota_info.concat(res.select{|m| m["_id"]["consumer"] == n})
end
total_ota_price = ota_info.map{|n| n["value"]["price"]}.reduce(:+).to_f.round(2)
total_ota_count = ota_info.map{|n| n["value"]["count"]}.reduce(:+).to_i


#### 销售额
top20= s.sort_by{|n| -n[1]}[0,20]
top20_list = top20.map{|n| n[0]}
p = [["", "总额", "OTA", "API其他"]]

top20.each do |n|
  p.first<<(n[0])
end

total_price = res.map{|n| n["value"]["price"]}.reduce(:+).round(2)
p_2 = ["求和/渠道销售价", total_price, total_ota_price, total_api_price]

top20.each do |n|
  p_2<< n[1]
end


p_3 = ["渠道GMV占比", ""] 
(2..23).each do |n|
  p p_2[n]
  p_3 << "#{Storage::Base.get_ratio(p_2[n], p_2[1])}%"
end

## 订单量

all_type = res.map{|n| n["_id"]["type"]}.uniq;nil

c = [["", "总量", "OTA", "API其他"]]
top20_list.each do |n|
  c.first<<(n)
end

total_count = res.map{|n| n["value"]["count"]}.reduce(:+).round(2)
c_2 = ["计数/订单状态",  total_count, total_ota_count, total_api_count]

top20_list.each do |n|
  c_2<< res.select{|m| m["_id"]["consumer"] == n}.map{|m| m["value"]["count"]}.reduce(:+).to_i
end


top20.each do |n|
  c_2<< n[1]
end

#各订单状态统计
# type_c = {}
# top20.each do |m,x|
#   all_type.each do |n|
#     type_c[m] ||= {}
#     type_c[m][n] = res.select{|k| k["_id"]["consumer"] == m && k["_id"]["type"] == n}.map{|v| v["value"]["count"]}.reduce(:+).to_i
#   end
# end

c_3 = ["渠道单量占比", ""] 
(2..23).each do |n|
  p c_2[n]
  c_3 << "#{Storage::Base.get_ratio(c_2[n], c_2[1])}%"
end

p << p_2
p << p_3

c << c_2
c << c_3
p.concat(c)



#### 第一个表格订单量没搞懂 (解释： 按照订单完成统计)




### 表格二 分产品类型占比

a << ["半日包", ]
## 半日包
half_count = res.select{|n| n["_id"]["type"] == "半日包"}.map{|n| n["value"]["count"]}.reduce(:+).to_i
small_long_distance_count = res.select{|n| n["_id"]["type"] =~ /包车/ && (n["_id"]["day_count"] >=1 && n["_id"]["day_count"]< 3)}.map{|n| n["value"]["count"]}.reduce(:+).to_i
air_booking_count = res.select{|n| n["_id"]["type"] =~ /接/ || n["_id"]["type"] =~ /送/ }.map{|n| n["value"]["count"]}.reduce(:+).to_i #单次接送

one_day_count = res.select{|n| n["_id"]["type"] == "一日包车"}.map{|n| n["value"]["count"]}.reduce(:+).to_i
air_arrive_count = res.select{|n| n["_id"]["type"] =~ /接/}.map{|n| n["value"]["count"]}.reduce(:+).to_i #接机
air_carry_count = res.select{|n| n["_id"]["type"] =~ /送/}.map{|n| n["value"]["count"]}.reduce(:+).to_i #送机
long_distance_count = res.select{|n|  n["_id"]["day_count"] > 3}.map{|n| n["value"]["count"]}.reduce(:+).to_i

type_list = ["半日包","小长途（1-3日包含）","单次接送","接机","市内包车（一日包）","送机","大长途（3日以上）",]
a = [["行标签", "单量", "占比"],
     ["半日包", half_count, "#{Storage::Base.get_ratio(half_count, total_count)}%"],
     ["小长途（1-3日包含）", small_long_distance,"#{Storage::Base.get_ratio(small_long_distance_count, total_count)}%"],
     ["单次接送", air_booking_count,"#{Storage::Base.get_ratio(air_booking_count, total_count)}%"],
     ["接机", air_arrive_count, "#{Storage::Base.get_ratio(air_arrive_count, total_count)}%"],
     ["市内包车（一日包）", one_day_count, "#{Storage::Base.get_ratio(one_day_count, total_count)}%"],
     ["送机", air_carry_count, "#{Storage::Base.get_ratio(air_carry_count, total_count)}%"],
     ["大长途（3日以上）", long_distance, "#{Storage::Base.get_ratio(long_distance_count, total_count)}%"],
     ["总计", total_count]

]






half_price = res.select{|n| n["_id"]["type"] == "半日包"}.map{|n| n["value"]["price"]}.reduce(:+).to_i
small_long_distance_price = res.select{|n| n["_id"]["type"] =~ /包车/ && (n["_id"]["day_count"] >=1 && n["_id"]["day_count"]< 3)}.map{|n| n["value"]["price"]}.reduce(:+).to_i
air_booking_price = res.select{|n| n["_id"]["type"] =~ /接/ || n["_id"]["type"] =~ /送/ }.map{|n| n["value"]["price"]}.reduce(:+).to_i #单次接送

one_day_price = res.select{|n| n["_id"]["type"] == "一日包车"}.map{|n| n["value"]["price"]}.reduce(:+).to_i
air_arrive_price = res.select{|n| n["_id"]["type"] =~ /接/}.map{|n| n["value"]["price"]}.reduce(:+).to_i #接机
air_carry_price = res.select{|n| n["_id"]["type"] =~ /送/}.map{|n| n["value"]["price"]}.reduce(:+).to_i #送机
long_distance_price = res.select{|n|  n["_id"]["day_count"] > 3}.map{|n| n["value"]["price"]}.reduce(:+).to_i

b = [["行标签", "销售价", "占比"],
     ["半日包", half_price, "#{Storage::Base.get_ratio(half_price, total_price)}%"],
     ["小长途（1-3日包含）", small_long_distance_price,"#{Storage::Base.get_ratio(small_long_distance_price, total_price)}%"],
     ["单次接送", air_booking_price,"#{Storage::Base.get_ratio(air_booking_price, total_price)}%"],
     ["接机", air_arrive_price, "#{Storage::Base.get_ratio(air_arrive_price, total_price)}%"],
     ["市内包车（一日包）", one_day_price, "#{Storage::Base.get_ratio(one_day_price, total_price)}%"],
     ["送机", air_carry_price, "#{Storage::Base.get_ratio(air_carry_price, total_price)}%"],
     ["大长途（3日以上）", long_distance_price, "#{Storage::Base.get_ratio(long_distance_price, total_price)}%"],

     ["总计", total_price]
]

### sheet2 end
#

city_res = base_booking.map_reduce(

  %Q{
       function(){
          var city = this.from_city;
          var price = this.total_rmb;
          var type = this.type;
          emit({city:city, type:type}, {price:price, count:1})
    }

  },
  %Q{
    function(key, items){
      var r = {price: 0, count: 0}
      items.forEach(function(item) {
        r.price += item.price
        r.count += item.count
      });
     return r;
    }
  }
).out(:inline => true).to_a


all_city = city_res.map{|n| n["_id"]["city"]}.uniq;nil
all_type = city_res.map{|n| n["_id"]["type"]}.uniq;nil

c_total_price = city_res.map{|n| n["value"]["price"]}.reduce(:+).round(2)
city_price = [["城市", "销售价", "占比"],
              ["总计", c_total_price]
]
city_price.first.concat(all_type)

c_tmp = []
all_city.each do |n|
  p = city_res.select{|m| m["_id"]["city"] == n}
  p_c = []
  all_type.each do |t|
    p_c << p.select{|x| x["_id"]["type"] == t}.map{|v| v["value"]["price"]}.reduce(:+).to_f.round(2)
  end
  c_p_price = p.map{|v| v["value"]["price"]}.reduce(:+).to_f.round(2)

  c_b = ([n, c_p_price, "#{Storage::Base.get_ratio(c_p_price, c_total_price)}%" ])

  c_tmp << c_b.concat(p_c)
end
city_price<< c_tmp.sort_by{|n| -n[1]}




c_total_count = city_res.map{|n| n["value"]["count"]}.reduce(:+).round(2)
city_count = [["城市", "计数", "占比"],
              ["总计", c_total_count]
]
city_count.first.concat(all_type)

c_tmp_count = []
all_city.each do |n|
  p = city_res.select{|m| m["_id"]["city"] == n}
  p_c = []
  all_type.each do |t|
    p_c << p.select{|x| x["_id"]["type"] == t}.map{|v| v["value"]["count"]}.reduce(:+).to_f.round(2)
  end
  c_p_count = p.map{|v| v["value"]["count"]}.reduce(:+).to_f.round(2)

  c_b = ([n, c_p_count, "#{Storage::Base.get_ratio(c_p_count, c_total_count)}%" ])

  c_tmp_count << c_b.concat(p_c)
end
city_count<< c_tmp_count.sort_by{|n| -n[1]}






