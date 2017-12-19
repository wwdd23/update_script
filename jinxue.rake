
ids = Consumer.where(:company_name => /途风/).map(&:id)

a = Booking.where(:paid_at.ne => nil,:status.ne => "退单完成", :consumer_id.in =>  [338, 339, 3862, 3899] )

res = a.map_reduce(
  %Q{
    function(){

       var day = new Date(this.paid_at* 1 + 1000 * 3600 * 8);
       var key_string = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));

       var pirce = this.total_rmb;
       var name = this.consumer_company;
       emit({date: key_string, consumer: name }, {price: this.total_rmb, count: 1});
    }
  },
  %Q{
    function(key,items){
       var r = {price: 0, count: 0};
       items.forEach(function(item){
         r.price += item.price;
         r.count += item.count;
       });
       return r;
    }
  }).out(:inline => true).to_a


send = [["时间", "公司名称", "支付金额(不含退单)", "订单量"]]

res.each do |n|
  send << [n["_id"]["date"], n['_id']["consumer"], n["value"]["price"], n["value"]["count"]]
end

Emailer.send_custom_file(['jinxue@haihuilai.com','zhouhong@haihuilai.com' ,'chenyilin@haihuilai.com'], "成都途风国际旅行社有限公司历史账单信息", XlsGen.gen(send), "成都途风国际旅行社有限公司历史账单信息.xls").deliver_now




$mongo_qspider['day_ctrip_casper.js'].find(:created_at => {:$gte => Time.parse(Time.now.to_date.to_s),:$lt => Time.now}).map{|n| n["data"]["city_cn"]}
"易途8"
城市 车型 日期 价格
send = [["", "", ""]]




time_span = (Time.now.tomorrow.to_date..Time.parse("2017-06-15")).map{|n| n.to_s}
result = {}
car_info = []
time_span.each do |span|
  $mongo_qspider['day_ctrip_casper.js'].find(:created_at => {:$gte => Time.parse(Time.now.to_date.to_s),:$lt => Time.now}).each do |n|

    cars = n['data']['data'].map{|m| m["name"]}
    base = n['data']['data']
    car_info.concat(cars)
    city_cn = n['data']["city_cn"]
    result[span] ||= {}
    result[span][city_cn] ||= {}
    cars.each do |m|
      info = base.select{|x| x["name"] == m }
      if info.present? 
        if info.first["datas"].select{|f| f["supply"] == "易途8"}.present?
          p  info.first["datas"].select{|f| f["supply"] == "易途8"}
          result[span][city_cn][m] = info.first["datas"].select{|f| f["supply"] == "易途8"}.first["sprice"] 
        else
          result[span][city_cn][m] = nil 
        end
      else
        result[span][city_cn][m] = nil
      end
    end
  end
end



city = ["爱丁堡", "伯明翰", "伦敦", "曼彻斯特", "尼斯", "马赛", "布拉格", "法兰克福", "杜赛尔多夫", "都灵", "雅典", "布鲁塞尔", "里斯本", "巴黎"]
out = [["时间", "国家"]]
out[0].concat(car_info.uniq)

cars = car_info.uniq

time_span.each do |t|
  city.each do |city|
    info = result[t][city]
    next unless info.present?
    p info
    inside = []
    inside = [t, city]
    p info
    cars.each do |car|
      p info[car]
      inside.push(info[car])
    end
    out << inside
  end
end



time_span.each do |t|
  car_info.uniq.each do |n|

    out << []


  end
end


"2016-10-3" => {
  "巴黎" => {
    "车型" => pirce
  }
}
Emailer.send_custom_file(['jinxue@haihuilai.com', 'chenyilin@haihuilai.com'], "携程易途8数据一日包车数据", XlsGen.gen(out), "携程易途8包车数据数据.xls").deliver_now
Emailer.send_custom_file(['jinxue@haihuilai.com','zhouhong@haihuilai.com' ,'chenyilin@haihuilai.com'], "成都途风国际旅行社有限公司历史账单信息", XlsGen.gen(send), "成都途风国际旅行社有限公司历史账单信息.xls").deliver_now




# 接团名义筛选 => 所有真是订单中， consumer_name 中不包含 company 信息的订单 
send = [["订单号", "接团名义", "采购商", "下单人", "op", "责任BD" ]]

Booking.real_order.each do |n|
  if n.consumer_name.include?(n.consumer_company) == false
    send << [n.booking_param, n.type , n.consumer_name, n.consumer_company, n.creater_name, n.op, n.sell_name]
  end
end
Emailer.send_custom_file(['wudi@haihuilai.com'], "接团名义与采购商公司名称不一致的订单信息", XlsGen.gen(send), "接团名义信息.xls").deliver_now






x = Booking.where(:paid_at.ne => nil,:type => /包车/,:status.ne => "退单完成", :memo.nin => [/门票/,/酒店/, /餐费/, /车票/, /超时费/]).count







a = Booking.real_order.where(:paid_at => Time.parse("2015-12-01")..Time.parse("2017-01-01")).where(:status.ne => "退单完成")
b = Booking.real_order.where(:paid_at => Time.parse("2017-01-01")..Time.now).where(:status.ne => "退单完成")




   all_booking_data = a.map_reduce(
      %Q{
        function(){
            var price = this.total_rmb;
            var name = this.consumer_company;


            emit( {name: name}, {price: price} )
        }
      },
        %Q{
        function(key, items){
            var r = {price: 0}
            items.forEach( function(item) {
              r.price += item.price;
            });
            return r;
        }
      }).out(:inline => true).to_a


   next_info = b.map_reduce(
      %Q{
        function(){
            var price = this.total_rmb;
            var name = this.consumer_company;


            emit( {name: name}, {price: price} )
        }
      },
        %Q{
        function(key, items){
            var r = {price: 0}
            items.forEach( function(item) {
              r.price += item.price;
            });
           return r;
        }
      }).out(:inline => true).to_a



first = all_booking_data.sort_by{|n| -n["value"]["price"]}[0,10].map{|n| [n["_id"]["name"], n["value"]["price"].to_f.round(2)]}
second = next_info.sort_by{|n| -n["value"]["price"]}[0,10].map{|n| [n["_id"]["name"], n["value"]["price"].to_f.round(2)]}


Emailer.send_custom_file(['wudi@haihuilai.com'], "销售额前十采购商统计", XlsGen.gen(first,second), "销售额前十采购商统计.xls").deliver_now



send = [["机场", "目的地", "类型", "供应商", "价格"]]
$mongo_qspider['air_ctrip_casper.js'].find().each do |n|
  data = n["data"]
  airport = data["airport_cn"]

  address = data["address_cn"]
  type = data["type_cn"]
  list = data["data"]
  list.each do |m|

    p m
    info = m["datas"]
    p info
    if info.present? 
      info.each do |x|
        supply = x["supply"]
        sprice = x["sprice"]
        p supply
        send << [airport, address, type, supply, sprice]
      end
    else
      p "jlasjdf"
      send << [airport, address, type, nil, nil]
    end

  end

end


## 采购商流水够10W


Booking.real_order.map_reduce



next_info = Booking.real_order.where(:paid_at => Time.parse("2016-10-01")..Time.parse("2017-09-01"), :status.ne => "退单完成" ).map_reduce(
  %Q{
        function(){
            var price = this.total_rmb;
            var name = this.consumer_company;


            emit( {name: name, sell_name: this.sell_name}, {price: price} )
        }
  },
    %Q{
        function(key, items){
            var r = {price: 0}
            items.forEach( function(item) {
              r.price += item.price;
            });
           return r;
        }
  }).out(:inline => true).to_a


out = [["销售" , "采购商", "最后支付时间", "金额"]]
next_info.select{|n| n["value"]["price"] >= 100000}.sort_by{|m| -m["value"]["price"]}.each do |n|
  last_paid = Booking.where(:consumer_company => n["_id"]["name"], :paid_at.ne => nil, :status.ne => "退单完成").last.try(:paid_at).to_date
  out << [n["_id"]["sell_name"], n["_id"]["name"], last_paid, n["value"]["price"].round(2)]
end

out2 = [["销售" , "采购商", "最后支付时间", "金额"]]

next_info.select{|n|  n["value"]["price"] >= 50000 && n["value"]["price"] <= 100000 }.sort_by{|m| -m["value"]["price"]}.each do |n|
  last_paid = Booking.where(:consumer_company => n["_id"]["name"], :paid_at.ne => nil, :status.ne => "退单完成").last.try(:paid_at).to_date
  out2 << [n["_id"]["sell_name"], n["_id"]["name"], last_paid, n["value"]["price"].round(2)]
end


out3 = [["销售" , "采购商", "最后支付时间", "金额"]]

next_info.select{|n|  n["value"]["price"] >= 0 && n["value"]["price"] <= 50000}.sort_by{|m| -m["value"]["price"]}.each do |n|
  p n
  last_paid = Booking.where(:consumer_company => n["_id"]["name"], :paid_at.ne => nil, :status.ne => "退单完成").last.try(:paid_at).to_date
  out3 << [n["_id"]["sell_name"], n["_id"]["name"], last_paid, n["value"]["price"].round(2)]
end

Emailer.send_custom_file(['jinxue@haihuilai.com','tongchang@haihuilai.com'], "201610月至今流水统计-区分销售", XlsGen.gen(out, out2, out3), "区分销售-三挡流水统计.xls").deliver_now


bds = Storage::Base::MG_AREA_BD

r = Booking.where(:paid_at => Time.parse("2016-10-01")..Time.parse("2016-10-01"), :status.ne => "退单完成").map_reduce(
  %Q{
        function(){
            var price = this.total_rmb;
            var name = this.sell_name;


            emit( name, {price: price} )
        }
  },
    %Q{
        function(key, items){
            var r = {price: 0}
            items.forEach( function(item) {
              r.price += item.price;
            });
           return r;
        }
  }).out(:inline => true).to_a

out = [["区域", "BD", "金额"]]
bds.each do |x, y|
  s_name = y[:name].first
  out << [x, s_name , r.select{|m| m["_id"] == s_name}.first["value"]["price"]]
end




Booking.where(:paid_at => Time.parse("2017-08-01")..Time.parse("2017-09-01"),:status.ne => '退单完成', :zone => /欧洲/,:sell_name.in => ["刘燕", "卢刚", "张海英"]).map(&:profit_company).reduce(:+)
Emailer.send_custom_file(['wangxuezheng@haihuilai.com','jasmine@haihuilai.com' ,'tongchang@haihuilai.com'], "首汽历史城市查询统计", XlsGen.gen(out), "首汽历史城市查询统计.xls").deliver_now




out = [["公司名称", "账号类型", "创建人", "总支付", "实际成交金额", "退款金额", "订单量", "实际成交量", "退款单量", 
        "历史登陆次数", 
        "多日包车金额", "多日包车单量",  
        "一日包车金额", "一日包车单量",
        "接机金额", "接机单量", "送机金额",
        "送机单量", "接站金额", "接站单量", 
        "送站金额", "送站单量",
        "精品线路金额", "精品路线单量", "半日包车金额", "半日包车单量"
]]


Consumer.where(:review_status => "审核通过").each do |n|
  name = n.company_name
  type = n.manager_id.nil? ? "主账号": "子账号"
  fullname = n.fullname
  consumer_id = n.id
  base_book = Booking.where(:consumer_id => consumer_id)

  sign_in_count = n.sign_in_count
  p n
  base_book_paid = base_book.where(:paid_at.ne => nil)
  if  base_book_paid.present? 

    first_res = []
    book_paid_count = base_book_paid.count 

    all_paid = base_book_paid.map(&:total_rmb).reduce(:+).to_f.round(2) 

    base_real_all_paid = base_book_paid.where(:status.ne => "退单完成")
    real_all_paid = base_real_all_paid.map(&:total_rmb).reduce(:+).to_f.round(2)

    real_all_count = base_real_all_paid.count

    base_drawback = base_book_paid.where(:status => "退单完成")

    drawback_price = base_drawback.map(&:total_rmb).reduce(:+).to_f.round(2)

    reduce_paid = base_book_paid.without_drawback.map_reduce(
      %Q{
           function(){
               var price = this.total_rmb;
               var type = this.type;


               emit( type, {price: price, count: 1} )
           }
      },
        %Q{
           function(key, items){
               var r = {price: 0, count: 0}
               items.forEach( function(item) {
                 r.price += item.price;
                 r.count += item.count;
               });
              return r;
           }
      }).out(:inline => true).to_a


    all_type =  ["多日包车", "一日包车", "接机", "送机", "接站", "送站", "精品线路", "半日包车"]

    data_type = []
    all_type.each do |n|
      r = reduce_paid.select{|m| m["_id"] == n}.first
      data_type << (r.present? ? r["value"]["price"].to_f : 0.to_f)
      data_type << (r.present? ? r["value"]["count"].to_i : 0)
    end

    
    p all_paid
    p real_all_paid
    first_res = [name, type, fullname, all_paid, real_all_paid,  drawback_price, book_paid_count, real_all_count, base_drawback.count, sign_in_count]
    out << first_res.concat(data_type)
  else
    out << [name, type, fullname  , nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,]

     
  end 



end


Emailer.send_custom_file(['wudi@haihuilai.com',], "采购商信息统计", XlsGen.gen(out), "采购商统计信息.xls").deliver_now





a = Booking.real_order.where(:paid_at => Time.parse("2016-10-01")..Time.parse("2017-01-01"),:status.ne => "退单完成" )

res = a.map_reduce(
  %Q{
    function(){

       var day = new Date(this.paid_at* 1 + 1000 * 3600 * 8);
       var key_string = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));

       var pirce = this.total_rmb;
       var name = this.consumer_company;
       emit({date: key_string, consumer: name ,type: this.type}, {price: this.total_rmb, count: 1});
    }
  },
  %Q{
    function(key,items){
       var r = {price: 0, count: 0};
       items.forEach(function(item){
         r.price += item.price;
         r.count += item.count;
       });
       return r;
    }
  }).out(:inline => true).to_a

types = a.pluck(&:type)

span = (Time.parse("2017-07-01").to_date..Time.parse("2017-09-01").to_date).map{|n| n.strftime("%Y-%m")}.uniq
c = a.map{|n|n.consumer_company}.uniq

out = [[ "2016-10", "2016-11", "2016-12", "2017-01", "接机", "送机", "多日包车", "一日包车", "送站"]]


out = [["采购商", "最后登陆时间",
        "2016-10",
        "2016-10接机",
        "2016-10送机",
        "2016-10多日包车",
        "2016-10一日包车",
        "2016-10送站",
        "2016-11",
        "2016-11接机",
        "2016-11送机",
        "2016-11多日包车",
        "2016-11一日包车",
        "2016-11送站",
        "2016-12",
        "2016-12接机",
        "2016-12送机",
        "2016-12多日包车",
        "2016-12一日包车",
        "2016-12送站",
        "2017-01",
        "2017-01接机",
        "2017-01送机",
        "2017-01多日包车",
        "2017-01一日包车",
        "2017-01送站"
]]

w = []
span.each do |n|
  types.each do |m|
    w <<   "#{n}, #{n}#{m}"
  end
end

out.first.concat(w)
c.each do |con|

  tmp1 = [con, Consumer.where(:company_name => con, :last_sign_in_at.ne => nil).map(&:last_sign_in_at).last, ]
  span_out= []
  span.each do |d|
    p con
    p d

    base_data = res.select{|x| x["_id"]["consumer"] == con && x["_id"]["date"] == d}
    span_out << (base_data.present? ? base_data.map{|m| m["value"]["price"]}.reduce(:+).to_f.round(2) : 0)
    types_out = []
    types.each do |t|
      p t
      if base_data.present? 
        e = base_data.select{|m| m["_id"]["type"] == t}.first
        types_out << (e.present? ?  e["value"]["price"].to_f.round(2) : 0)
      else
        types_out << 0
      end
    end
    span_out.concat(types_out)
  end
  tmp1.concat(span_out)
  out << tmp1
end

Emailer.send_custom_file(['wudi@haihuilai.com'], "2016/11~12月采购商统计", XlsGen.gen(out), "2016/11~12月采购商统计.xls").deliver_now

a = Booking.real_order.where(:paid_at => Time.parse("2017-7-01")..Time.parse("2017-10-01"),:status.ne => "退单完成" )

res = a.map_reduce(
  %Q{
    function(){

       var day = new Date(this.paid_at* 1 + 1000 * 3600 * 8);
       var key_string = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));

       var pirce = this.total_rmb;
       var name = this.consumer_company;
       emit({date: key_string, consumer: name}, {price: this.total_rmb, count: 1});
    }
  },
  %Q{
    function(key,items){
       var r = {price: 0, count: 0};
       items.forEach(function(item){
         r.price += item.price;
         r.count += item.count;
       });
       return r;
    }
  }).out(:inline => true).to_a

country_out = [["国家", "单量"]]
city_out = [["城市", "单量"]]


out = [["采购商", "成交金额"]]
out2 = [["201707~09","采购商", "成交金额"]]

res.sort_by{|n| -n["value"]["price"]}[0,10].each do |m|
  #city_out << [m["_id"]["consumer"], m["value"]["price"]]
  out2 << [nil, m["_id"]["consumer"], m["value"]["price"]]
  #country_out << [m["_id"]["country"], m["value"]["count"]]
end


out = [["月份", "多日包车", "一日包车", "接机", "送机", "送站", "接站"]]
types = a.map(&:type).uniq

span.each do |n|
  t = [n]
  types.each do |m|
    base = res.select{|x| x["_id"]["date"] == n && x["_id"]["type"] == m}.first
    p m
    p n
    t << (base.present? ? base["value"]["count"].to_i : 0)
  end
  out<< t
end

Emailer.send_custom_file(['jinxue@haihuilai.com'], "201607~10订单类型数量统计", XlsGen.gen(out), "201607~-10订单类型数量统计.xls").deliver_now

Emailer.send_custom_file(['jinxue@haihuilai.com'], "07-09采购商同期流水统计", XlsGen.gen(out,out2), "07-09采购商同期流水统计.xls").deliver_now




# 9月top 10 城市信息
#
res = Booking.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"),:status.ne => "退单完成" ).map_reduce(
  %Q{
    function(){
      var country = this.from_country;
      var city = this.from_city;
      var price = this.total_rmb;
      //emit({country: country, city:city }, {price: this.total_rmb, count: 1})
      emit({country: country }, {price: this.total_rmb, count: 1})
    }
  },
  %Q{ 
    function(key, items){
      var r = {price: 0, count:0}
      items.forEach(function(item){
        r.price += item.price;
        r.count += item.count;
      })
      return r;
    }
  }
).out(:inline => true).to_a

out = [["国家", "成交额", "单量", "平均单价"]]
res.sort_by{|x| -x["value"]["count"]}[0,20].each do |n|
  out << [n["_id"]["country"], n["value"]["price"],  n["value"]["count"].to_i, (n["value"]["price"] / n["value"]["count"]).to_f.round(2)]
end






send = [["单号", "下单时间", "出发时间", "结束时间", "出发城市", "用车时长(天)", "类型"]]
Booking.where(:created_at => Time.parse("2017-09-01")..Time.parse("2017-10-01"),:status.ne => "退单完成", :paid_at.ne => nil).each do |n|

  num = n.booking_param
  start_date = n.from_date
  end_date = n.to_date
  send << [num, n.created_at.to_date, start_date, end_date, n.from_city, n.day_count, n.type]
end



Emailer.send_custom_file(['wudi@haihuilai.com',], "Top10国家信息及9月成交订单用车时长统计", XlsGen.gen(out,send), "Top10国家信息及9月成交订单用车时长统计.xls").deliver_now

Emailer.send_custom_file(['wudi@haihuilai.com',], "Top20国家信息", XlsGen.gen(out), "Top20国家信息.xls").deliver_now

       var day = new Date(this.paid_at* 1 + 1000 * 3600 * 8);
res = Booking.paid.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-10-01"),:status.ne => "退单完成",).map_reduce(
  %Q{
    function(){
       var day = new Date(this.paid_at);
       var key_string = day.getFullYear() + "-" + ( (day.getMonth() + 1));
       var k = day.getFullYear() + "-" + ( (day.getMonth() + 1)) + '-' + (day.getDate() );

      emit({date: key_string, k:k, time: day, type: this.type }, {price: this.total_rmb, supplier_price: this.supplier_total_rmb, count: 1})
    }
  },
  %Q{ 
    function(key, items){
      var r = {price: 0, supplier_price:0 ,count:0}
      items.forEach(function(item){
        r.price += item.price;
        r.supplier_price += item.supplier_price;
        r.count += item.count;
      })
      return r;
    }
  }
).out(:inline => true).to_a



out = [["月度", "订单类型", "汇总金额", "供应总价", "单量", "客单价", "毛利"]]
res.each do |n|
  out << [n["_id"]["date"], n["_id"]["type"], n["value"]["price"].round(2), n["value"]["supplier_price"].round(2), 
          n["value"]["count"].to_i, (n["value"]["price"] / n["value"]["count"]).round(2), 
          (n["value"]["price"].round(2) -  n["value"]["supplier_price"].round(2)).round(2)

  ]
end
Emailer.send_custom_file(['hanguang@haihuilai.com',], "2017各月已成交订单类型毛利", XlsGen.gen(out), "2017各月已成交订单类型毛利统计.xls").deliver_now



Time.parse("2017-01-01").to_date..Time.parse("2017-10-01").to_date.to_date
Time.now.beginning_of_year.to_date..Time.parse("2017-10-01").to_date




# 卢刚名下采购商列表
#
send = [["id", "公司名称", "注册人", "账户类型", "支付方式", "联系方式", "审核状态"]]
Consumer.where(:admin_user => "卢钢").each do |n|
  type = n.manager_id.nil? ? "主账号": "子账号"
  send << [n.id, n.company_name, n.fullname, type, n.payment_type, n.email, n.review_status]

end
Emailer.send_custom_file(['wudi@haihuilai.com'], "卢钢名下采购商信息", XlsGen.gen(send), "卢刚名下采购商信息.xls").deliver_now


# 欧洲利润统计
#

start_day = Time.now.beginning_of_month
end_day = Time.now.end_of_month

span = start_day..end_day
Booking.where(:paid_at => start_day..end_day, :zone => /欧洲/).count

Booking.where(:paid_at => span,:status.ne => '退单完成', :zone => /欧洲/,:sell_name.in => ["刘燕", "卢刚", "张海英", "董洋洋"]).map(&:profit_company).reduce(:+)



# API 订单统计
#
#

start_day = Time.now.beginning_of_month
end_day = Time.now.end_of_month

span = Time.parse("2017-10-01")..Time.parse("2017-11-01")
span = Time.parse("2017-09-01")..Time.parse("2017-10-01")
all = Booking.real_order.where(:paid_at => span, :zone => /欧洲/,:status.ne => "退单完成")

all.map(&:total_rmb).reduce(:+)
all.map(&:company_profit).reduce(:+)





type = Booking.where(:paid_at => span,:status.ne => "退单完成").map(&:type).uniq
base =  Booking.where(:paid_at => span,:status.ne => "退单完成")

out = []
type.each do |n|

  t_b = base_booking.where(:type.in => [/机/, /站/])

  days = base_booking.map{|m| (m.from_date - m.created_at.to_date).to_i}.reduce(:+)

  base_booking.count

  ave = (days / t_b.count).round(2)
  out<< [n, ave, base_booking.count]
end




 接送机   24 天

 一日包车 16 天

 多日 22天


 十月平均 22 天


 # 10月金雪流水明细
r = Booking.where(:paid_at => span , :sell_name => "金雪", :status.ne => "退单完成", :consumer_company.nin => [/德铁/, /旅行顾问/, /体博/, ])

out = [["采购商", "下单时间", "支付时间", "订单金额", "订单状态", "订单类型", "司导", "车型", "起始国家", "起始城市"]]

r.each do |n|

  out << [n.consumer_company, n.created_at.to_date, n.paid_at.to_date, n.total_rmb, n.status, n.type, n.driver_category, n.car_category, n.from_country, n.from_city]

end


 res = Booking.real_order.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-11-01"), :status.ne => "退单完成")

out = [["采购商", "下单时间", "支付时间", "订单金额", "订单状态", "订单类型", "司导", "车型", "起始国家", "起始城市"]]

res.each do |n|
  out << [n.consumer_company, n.created_at.to_date, n.paid_at.to_date, n.total_rmb, n.status, n.type, n.driver_category, n.car_category, n.from_country, n.from_city]
end


r = Booking.real_order.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-11-01"), :updated_at => Time.parse("2017-11-01")..Time.now, :status => "退单完成")
r.each do |n|
  out << [n.consumer_company, n.created_at.to_date, n.paid_at.to_date, n.total_rmb, n.status, n.type, n.driver_category, n.car_category, n.from_country, n.from_city]
end


Emailer.send_custom_file(['jinxue@haihuilai.com','luolan@haihuilai.com' ], "10月真实成交订单信息", XlsGen.gen(out), "10月真实成交订单信息.xls").deliver_now





base_booking = Booking.real_order.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-11-01"),:status.nin => [/退/], :total_rmb.in => rmb ).count



city = Booking.real_order.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-11-01"),:status.nin => [/退/], :total_rmb.in => rmb ).map(&:from_country)



types = base_booking.map(&:type).uniq



types.each do |n|
  
  base_booking.where(:type => n)
end


out = []

type.each do |n|

  t_b = base_booking.where(:type.in => [/机/, /站/])
  days = t_b.map{|m| (m.from_date - m.created_at.to_date).to_i}.reduce(:+)
  base_booking.count
  ave = (days / t_b.count).round(2)
  out<< [n, ave, base_booking.count]



  price = t_b.map(&:total_rmb).reduce(:+)
  e_price = (price / t_b.count).round(2)
end

o = []
citys.each do |n|
  x = base_booking.where(:from_city => n)
  ave_x = (x.map(&:total_rmb).reduce(:+).to_f / x.count).to_f
  o << [n, ave_x]
end



bds = Storage::Base::MG_AREA_BD
info = []
bds.map{|x,y| y[:name]}.each{|n| n.each{|m| info << m}}

base_booking = Booking.real_order.where(:paid_at => Time.parse("2017-09-01")..Time.parse("2017-10-01"),:status.nin => [/退/], :sell_name.in => info )


#销售周报统计数据

base_info = Booking.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"), :status.nin => ["退单完成", /失效/], :sell_name.in => info )

week_span = Time.parse("2017-11-03")..Time.parse("2017-11-11")
month_span = Time.parse("2017-11-01")..Time.parse("2017-12-01")

week_info = Booking.where(:paid_at => week_span, :status.nin => ["退单完成", /失效/], :sell_name.in => info )

out = [["销售", "本月总流水", "月包车", "月接送机", "月接送站", "本周新增流水", "本周包车", "本周接送机", "本周接送站", "本月签约数（仅主账号）", "新增签约数（本周主账号)", "本月新增子账号数量", "本周新增子账号数量"]]


info.each do |n|

  total_month = base_info.where(:sell_name => n)
  total_week = week_info.where(:sell_name => n)

  total_month_price = total_month.map(&:total_rmb).present? ? total_month.map(&:total_rmb).reduce(:+).round(2) : 0
  total_month_car = total_month.where(:type => /车/).present? ? total_month.where(:type => /车/).map(&:total_rmb).reduce(:+).round(2) : 0
  total_month_air = total_month.where(:type => /机/ ).present? ? total_month.where(:type => /机/).map(&:total_rmb).reduce(:+) : 0
  total_month_train = total_month.where(:type =>  /站/).present? ? total_month.where(:type => /站/).map(&:total_rmb).reduce(:+) : 0

  total_week_price = total_week.map(&:total_rmb).present? ? total_week.map(&:total_rmb).reduce(:+).round(2) : 0
  total_week_car = total_week.where(:type => /车/).present? ? total_week.where(:type => /车/).map(&:total_rmb).reduce(:+).round(2) : 0
  total_week_air = total_week.where(:type => /机/).present? ? total_week.where(:type => /机/).map(&:total_rmb).reduce(:+) : 0
  total_week_train = total_week.where(:type => /站/).present? ? total_week.where(:type => /站/).map(&:total_rmb).reduce(:+) : 0

  base_new_consumer_month = Consumer.where(:reviewed_at => month_span, :review_status => "审核通过", :admin_user => n)
  base_new_consumer_week = Consumer.where(:reviewed_at => week_span, :review_status => "审核通过", :admin_user => n)

  count_month_f = base_new_consumer_month.where(:manger_id => nil).count
  count_month_c = base_new_consumer_month.where(:manger_id.ne => nil).count

  count_week_f = base_new_consumer_week.where(:manger_id => nil).count
  count_week_c = base_new_consumer_week.where(:manger_id.ne => nil).count

  out << [n, total_month_price, total_month_car, total_month_air, total_month_train, total_week_price, total_week_car, total_week_air, total_week_train, count_month_f, count_month_c,  count_week_f, count_week_c]
end




Emailer.send_custom_file(['jinxue@haihuilai.com'], "2017-11-03~11-10月报统计", XlsGen.gen(out), "2017-11-03~11-10月报统计.xls").deliver_now



span = Time.parse("2017-10-01")..Time.parse("2017-11-01")
a = Booking.where(:sell_name => "张海英", :paid_at => span, :status.ne => "退单完成").map(&:total_rmb).reduce(:+)
b = Booking.where(:sell_name => "张海英", :paid_at.ne =>span, :paid_at.ne => nil, :cancelled_at => span, :status.ne => "退单完成").map(&:total_rmb).reduce(:+)




# 2017年订单信息 单号  退款时间  订单状态  

out = [["订单号", "下单时间", "支付时间", "退款时间", "订单状态"]]
Booking.where(:paid_at => Time.parse("2017-01-01")..Time.now).each do |n|
  out << [n.booking_param, (n.paid_at.present? ? n.paid_at.to_time : nil), n.created_at.to_time, (n.cancelled_at.present? ? n.cancelled_at.to_time : nil), n.status]
end

Emailer.send_custom_file(['wudi@haihuilai.com'], "2017年订单状态详情统计", XlsGen.gen(out), "2017年订单状态详情统计.xls").deliver_now



# 周期结算账户个月订单统计

ids = [3522,22131,10878,6138,6108,5210,4685,3300,3299,1917,1726,1227,1050,799,22143,10812,10811,10282,6374,6137,6021,6005,5826,5474,5325,5213,5191,4990,4907,4817,4664,4295,3383,3221,3103,2894,2872,2867,2667,2618,2561,2280,2212,1663,1299,627,570,460,448,339,338,204,179,178,177,128,127,121,10860,10537,4246,370]


span = Time.parse("2015-01-01").to_date..Time.parse("2017-11-17").to_date

m = span.map do |n|
  n.strftime("%Y-%m")
end.uniq


out = [["ID", "采购商", "月份", "账号类型", "接送机金额", "接送站金额", "包车金额"]]
Consumer.where(:id.in => ids).each do |n|
  m.each do |mm|
    start_day = Time.parse("#{mm}-01")
    end_day = start_day.end_of_month
    base_booking = Booking.where(:consumer_id => n, :paid_at => start_day..end_day, :status.nin => [/退/])
    base_air = base_booking.where(:type => /机/)
    base_station = base_booking.where(:type => /站/)
    base_car = base_booking.where(:type => /车/)

    out << [n.id, n.company_name, mm, n.payment_type, (base_air.present? ? base_air.map(&:total_rmb).reduce(:+).round(2) : 0), 
            (base_station.present? ? base_station.map(&:total_rmb).reduce(:+).round(2) : 0), 
            (base_car.present? ? base_car.map(&:total_rmb).reduce(:+).round(2) : 0), 
    ]

  end
end


Emailer.send_custom_file(['wudi@haihuilai.com'], "周期账号月订单信息", XlsGen.gen(out), "周期账号月订单信息.xls").deliver_now 

a = Booking.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-11-01"),:status.ne => "退单完成" )

a.map(&:company_profit).reduce(:+).round(2)
a.map(&:total_rmb).reduce(:+).to_f.round(2)


res = a.map_reduce(
  %Q{
    function(){

       var pirce = this.total_rmb;
       var name = this.consumer_company;
       emit({consumer: name, bd:this.sell_name}, {price: this.total_rmb, profit: this.company_profit, count: 1});
    }
  },
  %Q{
    function(key,items){
       var r = {price: 0, profit: 0, count: 0};
       items.forEach(function(item){
         r.price += item.price;
         r.profit += item.profit;
         r.count += item.count;
       });
       return r;
    }
  }).out(:inline => true).to_a


send = [[ "公司名称", "BD", "支付金额(不含退单)", "利润", "订单量"]]

res.each do |n|
  send << [ n['_id']["consumer"], n['_id']["bd"], n["value"]["price"], n["value"]["profit"], n["value"]["count"]]
end
Emailer.send_custom_file(['hanguang@haihuilai.com'], "17采购商信息统计_总", XlsGen.gen(send), "17采购商信息统计_总.xls").deliver_now



### API 订单信息

span = Time.parse("2017-11-01").to_date..Time.parse("2017-12-01").to_date
Booking.where(:paid_at => span, :zone => /欧洲/, :status.ne => "退单完成").map(&:booking_param)


out= []
out << a
Emailer.send_custom_file(['wudi@haihuilai.com'], "欧洲订单", XlsGen.gen(a), "欧洲订单.xls").deliver_now


Booking.where(:paid_at => span,:status.ne => '退单完成', :zone => /欧洲/,:sell_name.in => ["刘燕", "卢刚", "张海英", "董洋洋"]).map(&:profit_company).reduce(:+)


# 每月信息 
# 11月top 10 国家信息
#
res = Booking.real_order.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"),:status.ne => "退单完成" ).map_reduce(
  %Q{
    function(){
      var country = this.from_country;
      var city = this.from_city;
      var price = this.total_rmb;
      //emit({country: country, city:city }, {price: this.total_rmb, count: 1})
      emit({country: country }, {price: this.total_rmb, count: 1})
    }
  },
  %Q{ 
    function(key, items){
      var r = {price: 0, count:0}
      items.forEach(function(item){
        r.price += item.price;
        r.count += item.count;
      })
      return r;
    }
  }
).out(:inline => true).to_a

out = [["国家", "成交额", "单量", "平均单价"]]
res.sort_by{|x| -x["value"]["count"]}[0,20].each do |n|
  out << [n["_id"]["country"], n["value"]["price"],  n["value"]["count"].to_i, (n["value"]["price"] / n["value"]["count"]).to_f.round(2)]
end




# 11月top 10 城市信息
#
res = Booking.real_order.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"),:status.ne => "退单完成" ).map_reduce(
  %Q{
    function(){
      var country = this.from_country;
      var city = this.from_city;
      var price = this.total_rmb;
      //emit({country: country, city:city }, {price: this.total_rmb, count: 1})
      emit({country: city}, {price: this.total_rmb, count: 1})
    }
  },
  %Q{ 
    function(key, items){
      var r = {price: 0, count:0}
      items.forEach(function(item){
        r.price += item.price;
        r.count += item.count;
      })
      return r;
    }
  }
).out(:inline => true).to_a

out_city = [["国家", "成交额", "单量", "平均单价"]]
res.sort_by{|x| -x["value"]["count"]}[0,20].each do |n|
  out_city << [n["_id"]["country"], n["value"]["price"],  n["value"]["count"].to_i, (n["value"]["price"] / n["value"]["count"]).to_f.round(2)]
end



res_ave = Booking.real_order.where(:paid_at => Time.parse("2017-11-01")..Time.parse("2017-12-01"),:status.ne => "退单完成" ).map_reduce(
  %Q{
    function(){
      var country = this.from_country;
      var type = this.type;

      var day = new Date(this.paid_at);
      var key_string = day.getFullYear() + "-" + (((day.getMonth() + 1) < 10 ? '0' : '') + (day.getMonth() + 1));

      var from_time =  new Date(this.from_date)

      var booking_id = this.booking_param
      var diff = from_time.getTime() - day.getTime()
      var days = parseInt(diff / (1000 * 60 * 60 * 24))
      //emit({country: country, city:city }, {price: this.total_rmb, count: 1})
      emit({type: type}, {days: days,  count: 1})
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


## 各类型单量 平均提前预定时长

out_type = [["类型", "单量", "平均预订周期时长"]]
res_ave.each do |n|
  out_type << [n["_id"]["type"], n["value"]["count"], (n["value"]["days"] / n["value"]["count"]).to_i]
end



Emailer.send_custom_file(['wudi@haihuilai.com'], "11月统计数据信息-移除走账订单", XlsGen.gen(out, out_city, out_type), "11月统计数据信息-移除走账订单.xls").deliver_now
