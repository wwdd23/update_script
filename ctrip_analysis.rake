# ctrip 订单信息
#
#
# 14日启动后订单信息
#
#
span = Time.parse("2017-12-15").to_date..Time.parse("2017-12-21").to_date
base_booking = Booking.where(:created_at => span,:consumer_company => "携程API采购账号", :cancel_memo.ne => "测试取消订单")



out =[["单号", "下单时间",  "支付时间", "订单状态", "提前下单天数", 
       "采购商", "供应商", "车型", "出发国家", "出发城市", 
       "出行日期", "结束时间", "类型", "采购金额", 
       "采购本币金额", "供应金额", "供应本币金额",  
       "币种",  "汇率", "利润", "携程订单真实利润", "订单状态"]]

base_booking.each do |n|


  days = (n.from_date.to_date - n.created_at.to_date).to_i

  currency_name = n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:currency).try(:name_cn)

  out << [n.booking_param, n.created_at.to_date, n.paid_at.to_date, 
          n.status, days, n.consumer_company, n.supplier_name, n.car_category, n.from_country,
          n.from_city, n.from_date.to_date,  n.to_date.to_date, n.type,
          n.total_rmb, n.total_original_currency, n.supplier_total_rmb, 
          n.supplier_locale_price, currency_name, n.conversion_rate, n.company_profit,
         
          (n.total_rmb * 0.87 - n.supplier_price).round(2), 
          n.status
  ]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "携程订单信息", XlsGen.gen(out), "携程订单信息.xls" ).deliver_now

(Booking.already_paid.where(user_id: 22131).sum(:total_rmb) *0.87- Booking.already_paid.where(user_id: 22131).sum(:supplier_price)).to_f



# 携程下单出行日期统计


base_booking.map_reduce(
  %Q{
    function(){
      var country = this.from_city;
      var type = this.type;

      var day = new Date(this.paid_at);
      var key_string = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));

      var from_time =  new Date(this.from_date)

      var booking_id = this.booking_param
      var diff = from_time.getTime() - day.getTime()
      var days = parseInt(diff / (1000 * 60 * 60 * 24))
      //emit({country: country, city:city }, {price: this.total_rmb, count: 1})
      emit({city: city, type: type}, {days: days,  count: 1})
    }
  },
  %Q{ 
    function(key, items){
      var r = {days: 0, count:0}
      items.forEach(function(item){
        r.days += item.days;
        r.count += item.count;
      })
      return r;
    }
  }
).out(:inline => true).to_a




###  每日城市查询量，对应订单下单量/ 成单量   当日搜索量 /  下单量 => 查询转化率 
#


## 七日总查询量, 携程理论下单量, 对应下单量 / 成单量  当日搜索量 / 下单量  
#



## 携程近8日订单 移除非条件地区订单影响
#
#对应 非调价区域 查询量 携程计算理论下单值 与订单信息
#
#

citys = ["曼谷", "台北", "大阪", "洛杉矶", "伦敦"]

spider = CtripSpider.where(:created_at => span)
all_ids = spider.map{|n| [ n.res["CityID"], n.res["ScheduleList"].first["DepartCityName"]]}.uniq;nil

r = [["日期", "城市", "请求量", "抓取量", "真访问数量", "下单订单量", "成单量", "退单量", "下单转化率", "成单转化率"]]
span.each do |date|
  start_day = date
  end_day = date.tomorrow
  citys.each do |n|
    logs = CtripLog.where(:created_at => start_day..end_day, :city_name => n)
    ctrip_city = all_ids.select{|m| m[1] == n}.first
    
    spider_info = CtripSpider.where(:created_at => start_day..end_day, "res.CityID" => ctrip_city[0])
    logs_count = logs.count
    spiders_count = spider_info.count


    city_booking = Booking.where(:created_at => start_day..end_day,:consumer_company => "携程API采购账号", :cancel_memo.ne => "测试取消订单",:from_city => n )
    city_booking_count = city_booking.count
    city_paid_count = city_booking.where(:paid_at.ne => nil, :status.nin => [/退/]).count
    city_cancel_count = city_booking.where(:paid_at.ne => nil, :status.in => [/退/]).count
    real_log_count = (logs_count - spiders_count)
    ## 成单转化率
    if city_booking_count == 0 
      paid_ratio = 0
      create_ratio = 0
    else
      paid_ratio = ((city_paid_count.to_f / city_booking_count.to_f) * 100)
      create_ratio = (( city_booking_count.to_f / logs_count.to_f) * 100)
    end



    r << [date , n, logs_count, spiders_count, real_log_count, city_booking_count,
          city_paid_count, city_cancel_count, "#{create_ratio}%", "#{paid_ratio}%",]
  end
end

# 汇总近几日所有数据信息
r_all = [["城市", "请求量", "抓取量", "真访问数量", "下单订单量", "成单量", "退单量", "下单转化率", "成单转化率"]]
citys.each do |n|
  logs = CtripLog.where(:created_at => span, :city_name => n)
  ctrip_city = all_ids.select{|m| m[1] == n}.first
  spiders = CtripSpider.where(:created_at => span, "res.CityID" => ctrip_city[0])
  logs_count = logs.count
  spiders = spiders.count

  city_booking = Booking.where(:created_at => span,:consumer_company => "携程API采购账号", :cancel_memo.ne => "测试取消订单",:from_city => n )
  city_booking_count = city_booking.count
  city_paid_count = city_booking.where(:paid_at.ne => nil, :status.nin => [/退/]).count
  city_cancel_count = city_booking.where(:paid_at.ne => nil, :status.in => [/退/]).count
  real_log_count = (logs_count - spiders_count)
  ## 成单转化率
  if city_booking_count == 0 
    paid_ratio = 0
    create_ratio = 0
  else
    paid_ratio = ((city_paid_count.to_f / city_booking_count.to_f) * 100).round(4)
    create_ratio = (( city_booking_count.to_f / logs_count.to_f) * 100).round(4)
  end



  r_all << [ n, logs_count, spiders_count, real_log_count, city_booking_count,
        city_paid_count, city_cancel_count, "#{create_ratio}%", "#{paid_ratio}%", ]
end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "携程统计数据", XlsGen.gen(r, r_all), "携程统计数据.xls" ).deliver_now
