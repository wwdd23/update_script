out = [["订单号", "订单类型", "下单时间", "支付时间", "开始日期", "结束日期", "开始城市", "大区", "采购商公司", "采购商", "责任BD", "供应商", "驾驶员", "金额", "退款金额(采购商)", "退单金额（供应商)", "实际金额", "供应商价格", "订单状态", "导游级别", "车辆级别"]]





Booking.where(:from_date.gte => "2017-01-27".to_date, :to_date.lte => "2017-02-03".to_date , :paid_at.ne => nil ).each do |n|

  drawback_consumer = n.transaction.select{|x| x["type_cn"] == "退款"}
  drawback_supplier = n.transaction.select{|x| x["type_cn"] == "退单"}
  out << [
    n.booking_param,
    n.type,
    n.created_at,
    n.paid_at,
    n.from_date,
    n.to_date,
    n.from_city,
    n.zone,
    n.consumer.company_name,
    n.consumer.fullname,
    n.sell_name,
    n.supplier_name,
    n.driver_name,
    n.total_rmb,
    drawback_consumer.present? ? drawback_consumer.map{|n| n["amount"]}.reduce(:+) : 0, # 退款金额
    drawback_supplier.present? ? drawback_supplier.map{|n| n["amount"]}.reduce(:+) : 0, # 退单金额
    nil,# 实际金额
    n.supplier_total_rmb,
    n.status,
    n.driver_category,
    n.car_category,
  ]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "新年假期执行订单", XlsGen.gen(out), "新年假期执行订单.xls" ).deliver



send_out = [["id", "队名", "姓名", "地区","电话", "微信", "手机"]]
Supplier.where(:review_status_cn => "审核通过", :type_cn => "队长", :is_use => true ).each do |n|
  send_out << [n.id , n.team_name, n.fullname , n.country_name, n.email, n.weixin, n.moblie]
end


Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "审核通过队长信息", XlsGen.gen(send_out), "审核通过队长信息.xls" ).deliver



send =[["订单号","国家","目的地","派单人","供应商","金额","供应商价格","利润", "状态"]]
Booking.where(:paid_at => 30.days.ago.to_date.to_time..Time.now).each do |n|

  location = n.from_location
  send << [
    n.booking_param,
    n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:name_cn),
    n.from_city,
    n.op,
    n.supplier_name,
    n.total_rmb,
    n.supplier_total_rmb,
    n.company_profit,
    n.status,
  ]
end
Emailer.send_custom_file(['diaoxu@haihuilai.com','chenyilin@haihuilai.com'],  "过去30天供应商订单详情", XlsGen.gen(send), "过去30天供应商订单详情.xls" ).deliver




# ydj 一日包车数据导出



send = [['服务日期', '车型', '车辆种类', '座位数', '人数', '行李数', '行程总价(当地货币)', '人民币价', '币种', '空置费用(当地)', '汇率', '当地单价', '等待费', '城市ID', '城市', '餐费', '导游类型', '特殊服务状态', ]]


$mongo_qspider['ydj_batchprice.js'].find().each do |n|
  base = n['data']
  #childprice1 = base['dailyAdditionalServicePrice']['childSeatPrice1'].present? ? base['dailyAdditionalServicePrice']['childSeatPrice1'] : 0
  #childprice2 = base['dailyAdditionalServicePrice']['childSeatPrice2'].present? ? base['dailyAdditionalServicePrice']['childSeatPrice2'] : 0

  noneCarsParam = base["noneCarsParam"]
  noneCarsReason = base ["noneCarsReason"]
  noneCarsState = base["noneCarsState"]
  serviceDate = n['context']["start_date"]
  quoteinfo = base['quoteInfos']

  quoteinfo.each do |info|
    capOfLuggage = info['capOfLuggage']
    capOfPerson = info['capOfPerson']
    carDesc = info['carDesc']
    carIntroduction = info['carIntroduction']
    models = info['models']

    price = info['price']
    priceWithAddition = info['priceWithAddition']
    

    quotes = info['quotes']
    additionalServicePrice = quotes.first['additionalServicePrice']
    currency = quotes.first['currency']
    currencyRate = quotes.first['currencyRate']

    dayOriginPrice = quotes.first['dayOriginPrices'].first['dayOriginPrice']
    dayOriginPrices_day = quotes.first['dayOriginPrices'].first['day']

    emptyOriginPrice = quotes.first['emptyOriginPrice']
    index = quotes.first['index']
    mealDays= quotes.first['mealDays']
    mealPrice = quotes.first['mealPrice']
    originPrice = quotes.first['originPrice']
    originPriceWithAddition = quotes.first['originPriceWithAddition']
    quotes_price = quotes.first['price']
    quotes_priceWithAddition = quotes.first['priceWithAddition']

    quoteCityId = quotes.first["quoteCityId"]

    quoteCityName = quotes.first['quoteCityName']
    serviceType = quotes.first['serviceType']
    stayPrice = quotes.first['stayPrice']

    seatCategory = info['seatCategory']
    seatType = info['seatType']
    serviceTags = info['serviceTags']
    urgentCutdownTip = info['urgentCutdownTip']
    urgentFlag = info['urgentFlag']
    special = info['special']

    send << [
      serviceDate,
      carDesc,
      models,
      seatType,
      capOfPerson,
      capOfLuggage,
      dayOriginPrice,
      price,
      currency,
      emptyOriginPrice,
      currencyRate,
      originPrice,
      stayPrice,
      quoteCityId,
      quoteCityName,
      mealPrice,
      serviceTags,

      special,

    ]

  end
end



res = Supplier.where(:review_status_cn => "审核通过").map_reduce(
  %Q{
    function(){
      var country = this.country_name;
      var type = this.type_cn;
      emit({contry: country, type: type}, {count: 1});
    }
  },
  %Q{
    function(key,items) {
      var r = {count: 0};
      items.forEach(function(item){
        r.count += item.count;
      }) 
      return r;
    }
  }
  ).out(:inline => true).to_a


all_country = res.map{|n| n["_id"]["contry"]}.uniq

out = [["国家", "队长", "车导", "总数"]]

all_country.each do |n|
  info = res.select{|m| m["_id"]["contry"] == n}

  l = info.select{|m| m["_id"]["type"] == "队长"}
  c = info.select{|m| m["_id"]["type"] == "车导"}

  l_count = l.present? ? l.first["value"]["count"] : 0
  c_count = c.present? ? c.first["value"]["count"] : 0

  all_count = l_count + c_count

  out << [n, l_count.to_i, c_count.to_i, all_count.to_i]
end


empty_country = Supplier.where(:review_status_cn => "审核通过", :country_name.in => ["",nil])

send = [["id", "姓名", "所在国家", "服务区域", "类型"]]
empty_country.each do |n|
  name = n.fullname
  id = n.id
  country = n.country_name
  services = n.services_locations

  send << [id, name, country, services, n.type_cn]
end

### 供应商上半年统计

booking = Booking.where(:from_date.gte => Time.parse("2017-01-01"), :to_date.lte => Time.parse("2017-07-18"),:paid_at.ne => nil, :status => "订单完成")
res = booking.map_reduce(
  %Q{
    function(){
       var day = new Date(this.created_at * 1 + 1000 * 3600 * 8);
       var date = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));
       var supplier = this.supplier_name;
       var price = this.supplier_total_rmb;
       var type = this.type;
       emit({date: date, type: type, supplier:supplier}, {price: price, count: 1});
    }

  },
  %Q{
    function(key, items){
      var r = {price: 0, count: 0};
      items.forEach(function(item){
        r.price += item.price;
        r.count += item.count;
      })
      return r;
    }
  }).out(:inline => true).to_a



suppliers = res.map{|n| n["_id"]["supplier"]}.uniq

span = 7.month.ago.beginning_of_month.to_date..Time.now.beginning_of_month.to_date
step = span.map{|n| n.strftime("%Y-%m") }.uniq

out = [["供应商", "日期", "单量", "成交金额", "一日包车单量", "一日包车金额", "多日包车单量", "多日包车金额", 
        "接机单量", "接机金额", "送机单量", "送机金额"]]

step.each do |date|
  suppliers.each do |s|

    base_info = res.select{|n| n["_id"]["supplier"] == s && n["_id"]["date"] == date}

    count = base_info.present? ?  base_info.map{|m| m["value"]["count"]}.reduce(:+).to_i : 0
    all_price = base_info.present? ? base_info.map{|m| m["value"]["price"]}.reduce(:+).to_f.round(2) : 0

    one_day_count = base_info.select{|x| x["_id"]["type"] == "一日包车"}.present? ?  base_info.select{|x| x["_id"]["type"] == "一日包车"}.map{|m| m["value"]["count"]}.reduce(:+).to_i : 0 
    more_day_count = base_info.select{|x| x["_id"]["type"] == "多日包车"}.present? ?  base_info.select{|x| x["_id"]["type"] == "多日包车"}.map{|m| m["value"]["count"]}.reduce(:+).to_i : 0 
    pickup_count = base_info.select{|x| x["_id"]["type"] == "接机"}.present? ?  base_info.select{|x| x["_id"]["type"] == "接机"}.map{|m| m["value"]["count"]}.reduce(:+).to_i : 0 
    dropoff_count = base_info.select{|x| x["_id"]["type"] == "送机"}.present? ?  base_info.select{|x| x["_id"]["type"] == "送机"}.map{|m| m["value"]["count"]}.reduce(:+).to_i : 0 


    one_day_price = base_info.select{|x| x["_id"]["type"] == "一日包车"}.present? ?  base_info.select{|x| x["_id"]["type"] == "一日包车"}.map{|m| m["value"]["price"]}.reduce(:+).to_i : 0 
    more_day_price = base_info.select{|x| x["_id"]["type"] == "多日包车"}.present? ?  base_info.select{|x| x["_id"]["type"] == "多日包车"}.map{|m| m["value"]["price"]}.reduce(:+).to_i : 0 
    pickup_price = base_info.select{|x| x["_id"]["type"] == "接机"}.present? ?  base_info.select{|x| x["_id"]["type"] == "接机"}.map{|m| m["value"]["price"]}.reduce(:+).to_i : 0 
    dropoff_price = base_info.select{|x| x["_id"]["type"] == "送机"}.present? ?  base_info.select{|x| x["_id"]["type"] == "送机"}.map{|m| m["value"]["price"]}.reduce(:+).to_i : 0 

    out << [s, date, count, all_price, one_day_count, one_day_price, more_day_count, more_day_price, pickup_count, pickup_count, dropoff_count, dropoff_price ]

  end
end

Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "上半年供应商完成订单统计信息", XlsGen.gen(out), "上半年供应商统计信息.xls" ).deliver
Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "ydj—POI信息输出", XlsGen.gen(out), "ydj_poi信息.xls" ).deliver



["区域/位置（供应商所在）", "供应商", "供应商ID", "车导", "车导ID", "目的地(订单开始城市)", "订单类型", "开始时间", "结束时间", "导游等级", "订单的采购商", "订单的OP", "订单的下单人", "是否自动指派", "指派时间", "上传意见单", "供应商结算类型", "订单标识", "供应商金额（人民币）", "供应商金额（当地货币）"]



### 供应商 筛选方法
Supplier.where(:review_status_cn => "审核通过",:type => "CompanySupplier").count

# u
# 订单中供应商 
Booking.real_order.where(:status.ne => "退单完成")

## 国家订单姐统计
booking = Booking.real_order.where(:paid_at.ne => nil, :status.ne => "退单完成")
res = booking.map_reduce(
  %Q{
    function(){
       var country = this.from_country;
       var price = this.total_rmb;
       emit(country , {price: price, count: 1});
    }

  },
  %Q{
    function(key, items){
      var r = {price: 0, count: 0};
      items.forEach(function(item){
        r.price += item.price;
        r.count += item.count;
      })
      return r;
    }
  }).out(:inline => true).to_a

out = [["国家", "单量"]]
res.sort_by{|n| -n["value"]["count"]}.each do |n|
  out << [n["_id"], n["value"]["count"]]
end

Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "历史国家单量统计", XlsGen.gen(out), "历史国家单量统计.xls" ).deliver




t = Supplier.where(:review_status => "reviewed", :type => "CompanySupplier").map_reduce(
  %Q{
       function(){
           var day = new Date(this.reviewed_at * 1 + 1000 * 3600 * 8);
           if (parseInt(day.getMonth() + 1) >= 10) {
             month = (day.getMonth() + 1)
           } else {
             month = "0" +  (day.getMonth() + 1)
           }
           var date = day.getFullYear() + "-" + month;
           var status = this.review_status;
           var status_cn = this.review_status_cn;
           var count = 1;
           emit({date: date, status: status ,status_cn: status_cn }, {count: count})
       }
  },
    %Q{
       function(key, items){
        var r = {count: 0 }
        items.forEach(function(item) {
          r.count += item.count;
        })
        return r;
       }
  }
).out(:inline => true).to_a



total_count = t.map{|n| n["value"]["count"]}.reduce(:+)

date_span.each do |n|
  t.select{|x| x["_id"]["date"] <= n }.map{|y| y["_id"]["count"]}.reduce(:+).to_i
end






PriceTicket.where(:booking_type.in => ["非标订单", /fei booking/], :booking_params.ne => []).map(&:booking_param)



pt_ids = PriceTicket.where(:booking_type.in => ["非标订单", /fei booking/], :booking_params.ne => []).map(&:booking_params).flatten.uniq



out = [["订单号", "下单时间", "支付时间", "开始时间", "结束时间", 
        "开始城市", "结束城市", "途径城市", "途径城市详情", "车型", 
        "订单类型", "备注订单类型", "金额", "人数", "订单状态"]]

Booking.where(:booking_param.in => pt_ids).each do |n|


  detail = n.travel_items_detail

  p n
  p detail
  a_detail = []
  if detail.present? && detail != [nil]
    detail.each{|m| a_detail << m.gsub(/\s+/, ' ').strip}
  end


  out << [
    n.booking_param, n.created_at.present? ? n.created_at.to_date : nil, 
    n.paid_at.present? ? n.paid_at.to_date : nil, n.from_date, n.to_date, 
    n.from_city, n.to_city, n.travel_items_location, n.car_category, 
    n.type, n.back_booking_type, n.total_rmb, n.people_num, n.status
  ]

end



Emailer.send_custom_file(['xusiyuan@haihuilai.com', 'wangxuezheng@haihuilai.com'],  "历史非标订单路径信息", XlsGen.gen(out), "历史非标订单路径信息.xls" ).deliver_now
Emailer.send_custom_file(['wudi@haihuilai.com',],  "历史非标订单路径信息", XlsGen.gen(out), "历史非标订单路径信息.xls" ).deliver_now



# 供应商总量
# 审核通过
#  车导总量 
driver_all = []
driver_all << Supplier.where(:type => "DriverSupplier").map(&:fullname);nil
#审核通过车导总量
driver_all_compact = []
driver_all_compact << Supplier.where(:type => "DriverSupplier", :review_status_cn => "审核通过").map(&:fullname);nil

#供应商总量
s_all = Supplier.where(:type => "CompanySupplier")

s_all.count
s_names = []
s_names << s_all.map(&:fullname);nil
#审核通过供应商总量

c_s_all = Supplier.where(:type => "CompanySupplier", :review_status_cn => "审核通过")
c_s_all.count
c_s_all_name = []
c_s_all_name << c_s_all.map(&:fullname);nil

#历史接单车导数量
b_drivers = []
b_drivers <<  Booking.real_order.map(&:driver_name).uniq;nil

# 历史接单供应商数量
b_suppliers = []
b_suppliers <<  Booking.real_order.map(&:supplier_name).uniq;nil




Emailer.send_custom_file(['wudi@haihuilai.com',],  "历史非标订单路径信息", XlsGen.gen(driver_all, driver_all_compact, c_s_all_name, s_names, b_drivers, b_suppliers), "历史非标订单路径信息.xls" ).deliver_now



send = [["id", "姓名", "审核通过时间", "类型", "国家", "服务区域"]]
all = Supplier.where(:review_status_cn => "审核通过" )


all.each do |n|
  if n.type == "CompanySupplier" 
    type = "队长"
  else
    type = "车导"
  end
  send << [n.id, n.fullname, n.try(:reviewed_at), type, n.country_name, n.services_locations ]

end





Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "审核通过供应商地区信息", XlsGen.gen(send), "审核通过供应商地区信息.xls" ).deliver




# 线上包车查价 

a = [["阿布扎比", "2017-11-15"],["阿德莱德", "2017-11-15"],["阿姆斯特丹", "2017-11-15"],["阿维尼翁(亚维农)", "2017-11-15"],["爱丁堡", "2017-11-15"],["奥克兰", "2017-11-15"],["奥兰多", "2017-11-15"],["奥斯陆", "2017-11-15"],["巴黎", "2017-11-15"],["巴塞罗那", "2017-11-15"],["芭提雅", "2017-11-15"],["柏林", "2017-11-15"],["波尔多", "2017-11-15"],["波士顿", "2017-11-15"],["布拉格", "2017-11-15"],["布里斯班", "2017-11-15"],]


out = [["城市", "时间", "车型", "司导", "是否支持出城", "附加费", "城内价格", "城外价格"]]
a.each do |n|

  filter = {:form_class=>"one_day_form", :date=>n[1], :city=> n[0]}
  hhl_api_data =  Storage::Fetcher.day_booking_data(filter)
  res = hhl_api_data["data"]
  res.each do |m|
    out << [n[0], n[1], m["car_category_name"], m["driver_category_name"], 
            m["out_of_city"], m["additional_fee"], m["inside_city_price"],
            m["outside_city_price"]]
  end
end


Emailer.send_custom_file(['diaoxu@haihuilai.com'],  "线上包车价格列表信息", XlsGen.gen(out), "线上包车价格列表信息.xls" ).deliver
