
span =
Booking.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-11-01"),:sell_name => "张海英",:status.ne => "退单完成").



out = [["月份", "流水金额"]]
(1..11).each do |n|

  start_day = Time.parse("2017-#{n}-01")  
  end_day = Time.parse("2017-#{n}-01").end_of_month
 
  span = start_day..end_day
  all = Booking.where(:paid_at => span,:sell_name => "张海英",:status.ne => "退单完成").map(&:total_rmb).reduce(:+).round(2)
  out << [n, all]


end

## 销售绩效统计 kpi
## 按照服务开始时间统计

span = Time.parse("2017-12-01")..Time.parse("2018-01-01")


 bd_info = Storage::Base::MG_AREA_BD

 bds = []
 bd_info.map{|k,m| m[:name]}.each{|x| x.each{|y| bds << y}}

# 
# out =[["单号", "下单时间",  "支付时间", "bd", "订单状态", "采购商", "供应商", "出发国家", "出发城市", "出行日期", "结束时间", "类型", "采购金额", "采购本币金额", "供应金额", "供应本币金额",  "币种",  "汇率", "利润"]]
# Booking.where(:paid_at.ne => nil, :from_date => span, :sell_name.in => bds,  :status.not => /退/ ).each do |n|
#   currency_name = n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:currency).try(:name_cn)
#   out << [n.booking_param, n.created_at.to_date, n.paid_at.to_date, n.sell_name, 
#           n.status, 
#           n.consumer_company, n.supplier_name, n.from_country, n.from_city,
#           n.from_date.to_date,  n.to_date.to_date, n.type,
#           n.total_rmb, n.total_original_currency, n.supplier_total_rmb,
#           n.supplier_locale_price, currency_name, n.conversion_rate, n.company_profit]
# 
# end

out =[["单号", "下单时间",  "支付时间", "bd", "订单状态", "采购商", 
       "出发国家", "出发城市", "出行日期", "结束时间", "类型", 
       "采购金额",  "备注类型"
]]
base_booking = Booking.where(:paid_at.gte => Time.parse("2017-12-01"), :from_date => span, :sell_name.in => bds,  :status.not => /退/ )

base_booking.each do |n|
  currency_name = n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:currency).try(:name_cn)
  out << [n.booking_param, n.created_at.to_date, n.paid_at.to_date, n.sell_name, 
          n.status, 
          n.consumer_company, n.from_country, n.from_city,
          n.from_date.to_date,  n.to_date.to_date, n.type,
          n.total_rmb, currency_name, n.back_booking_type]

end

Emailer.send_custom_file(['wudi@haihuilai.com'],  "12月订单信息", XlsGen.gen(out), "订单基础信息.xls" ).deliver_now


send_bds_info = [["BD", "服务订单量", "服务单总金额", "包车单量", "包车金额", "接送机单量", "接送机金额",]]

bds.each do |n|
  sell_bookings = base_booking.where(:sell_name => n, :back_booking_type.nin => ["门票", "酒店", "餐费", "其他垫付"] )

  car_bookings = sell_bookings.where(:type => /车/)
  air_bookings = sell_bookings.where(:type.in => [/机/, /站/])

  send_bds_info << [n, sell_bookings.count, sell_bookings.map(&:total_rmb).reduce(:+).to_f,
                    car_bookings.count, car_bookings.map(&:total_rmb).reduce(:+).to_f,
                    air_bookings.count, air_bookings.map(&:total_rmb).reduce(:+).to_f,]

end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "#{span.first.to_date.to_s}销售统计数据", XlsGen.gen(send_bds_info, out), "#{span.first.to_date.to_s}销售统计数据.xls" ).deliver_now





### 王宇的订单信息统计
# 欧洲订单信息 添加
# 计算利润信息
#


