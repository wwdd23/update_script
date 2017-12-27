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

base_booking = Booking.real_order.where(:paid_at => Time.parse("2017-12-01")..Time.parse("2018-01-01"), :status.not => /退/)
res = base_booking.map_reduce(
  %Q{
  function(){
    var consumer = this.consumer_company
    var price = this.total_rmb
    var type = this.type
    emit({consumer: consumer, type: type, day_count: this.day_count}, {price: price, count: 1 })

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
all_company.each do |n|

  r = res.select{|m| m["_id"]["consumer"] == n}

  total_price = r.map{|m| m["value"]["price"]}.reduce(:+)

  s << [n, total_price]
end

ota_list = ["携程API采购账号"]
api_list =  ["伙力专车（API）", "上海久柏易游信息技术有限公司（900游API）", "首汽约车API",  "上海申悠旅游咨询有限公司API"]
ota = res.map{|m| m["_id"]["consumer"].include(ota_list)}

sheet1 = s.sort_by{|n| -n[1]}[0,20]






