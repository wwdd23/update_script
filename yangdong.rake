# 客户数

before_consumer = Consumer.where(:created_at.lte => Time.parse("2016-11-01"),:review_status => "审核通过").count


a = Consumer.where(:reviewed_at.gte => Time.parse("2016-11-01"),:review_status => "审核通过").count
b = Consumer.where(:reviewed_at => nil, :created_at => Time.parse("2016-11-01")..Time.parse("2016-12-01"), :review_status => "审核通过").count
# 11月客户数
a+b

Consumer.where(:reiewed_at.gte => Time.parse("2016-12-01"), :review_status => "审核通过").map_reduce(
)

consumer_data = Consumer.collection.aggregate([
  {
    :$match => {
      :created_at  => {:$gte => Time.parse("2016-12-01")},
      :review_status => "审核通过",
    }
  },
  { 
    :$group => {
      #:_id => '$reviewed_at',
      :_id => {"$substr" => [ {"$add" => ["$reviewed_at", 8*60*60000]}, 0, 7]},
      :sub_count => {:$sum => 1}
    }
  }

])



order = Booking.collection.aggregate([
  {
    :$match => {
      :created_at => {:$gte => Time.parse("2016-11-01")},
      :paid_at => {:$ne => nil},
      :review_status => {:$ne => "退单完成"},
      :op => {:$not => /测试/}
    }
  },{
    :$group => {
      :_id => {
      
        :date => {"$substr" => [ {"$add" => ["$paid_at", 8*60*60000]}, 0, 7]},
        :type => '$type',
      },
      :count => {:$sum => 1},
      :price => {:$sum => '$total_rmb'}
    }
  }
])



send = [["", "2016.11前", "2016.11后", "2016.11", "2016.12", "2017.01", "2017.02", "2017.03"]]


send << ["客户数", before_consumer, a+b+consumer_data.map{|n| n["sub_count"]}.reduce(:+),
         a+b, consumer_data.select{|n| n["_id"] == "2016-12"}.first["sub_count"], 
         consumer_data.select{|n| n["_id"] == "2016-12"}.first["sub_count"],
         consumer_data.select{|n| n["_id"] == "2017-01"}.first["sub_count"],
         consumer_data.select{|n| n["_id"] == "2017-02"}.first["sub_count"],
         consumer_data.select{|n| n["_id"] == "2017-03"}.first["sub_count"],
]

send << [ "订单数", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成").count,
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成").count,
          order.select{|n| n["_id"]["date"] == "2016-11"}.map{|m| m["count"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2016-12"}.map{|m| m["count"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-01"}.map{|m| m["count"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-02"}.map{|m| m["count"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-03"}.map{|m| m["count"]}.reduce(:+).round(2),
]

send << [ "交易额", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:total_rmb).reduce(:+).round(2),
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:total_rmb).reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2016-11"}.map{|m| m["price"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2016-12"}.map{|m| m["price"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-01"}.map{|m| m["price"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-02"}.map{|m| m["price"]}.reduce(:+).round(2),
          order.select{|n| n["_id"]["date"] == "2017-03"}.map{|m| m["price"]}.reduce(:+).round(2),
]



paid_consumer = Booking.collection.aggregate([
  {
    :$match => {
      :created_at => {:$gte => Time.parse("2016-11-01")},
      :paid_at => {:$ne => nil},
      :review_status => {:$ne => "退单完成"},
      :op => {:$not => /测试/}
    }
  },{
    :$group => {
      :_id => {

        :date => {"$substr" => [ {"$add" => ["$paid_at", 8*60*60000]}, 0, 7]},
        :consumer_name => '$consumer_name',
        :consumer_company => '$consumer_company',
      },
      :count => {:$sum => 1},

    }
  }
])

name_consumer_paid_before = Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:consumer_name).uniq.count
name_consumer_paid_after = Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:consumer_name).uniq.count

company_consumer_paid_before = Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:consumer_company).uniq.count
company_consumer_paid_after = Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成").map(&:consumer_company).uniq.count



send << ["有交易账户(注册人)",  name_consumer_paid_before, name_consumer_paid_after, 
         paid_consumer.select{|n| n["_id"]["date"] == "2016-11"}.map{|m| m["_id"]["consumer_name"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2016-12"}.map{|m| m["_id"]["consumer_name"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-01"}.map{|m| m["_id"]["consumer_name"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-02"}.map{|m| m["_id"]["consumer_name"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-03"}.map{|m| m["_id"]["consumer_name"]}.uniq.count,
]
send << ["有交易账户(公司)", company_consumer_paid_before, company_consumer_paid_after,
         paid_consumer.select{|n| n["_id"]["date"] == "2016-11"}.map{|m| m["_id"]["consumer_company"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2016-12"}.map{|m| m["_id"]["consumer_company"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-01"}.map{|m| m["_id"]["consumer_company"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-02"}.map{|m| m["_id"]["consumer_company"]}.uniq.count,
         paid_consumer.select{|n| n["_id"]["date"] == "2017-03"}.map{|m| m["_id"]["consumer_company"]}.uniq.count,
]


send << [ "接送机", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :type.in => [/接/,/送/]).count,
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :type.in => [/接/,/送/]).count,
          order.select{|n| n["_id"]["date"] == "2016-11" &&  (n["_id"]["type"].match(/接/) || n["_id"]["type"].match(/送/))}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2016-12" &&  (n["_id"]["type"].match(/接/) || n["_id"]["type"].match(/送/))}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-01" &&  (n["_id"]["type"].match(/接/) || n["_id"]["type"].match(/送/))}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-02" &&  (n["_id"]["type"].match(/接/) || n["_id"]["type"].match(/送/))}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-03" &&  (n["_id"]["type"].match(/接/) || n["_id"]["type"].match(/送/))}.map{|m| m["count"]}.reduce(:+),
]

send << [ "包车", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :type => /包车/).count,
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :type => /包车/).count,
          order.select{|n| n["_id"]["date"] == "2016-11" &&  n["_id"]["type"].match(/包/)}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2016-12" &&  n["_id"]["type"].match(/包/)}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-01" &&  n["_id"]["type"].match(/包/)}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-02" &&  n["_id"]["type"].match(/包/)}.map{|m| m["count"]}.reduce(:+),
          order.select{|n| n["_id"]["date"] == "2017-03" &&  n["_id"]["type"].match(/包/)}.map{|m| m["count"]}.reduce(:+),
]




op = Booking.collection.aggregate([
  {
    :$match => {
      :created_at => {:$gte => Time.parse("2016-11-01")},
      :paid_at => {:$ne => nil},
      :review_status => {:$ne => "退单完成"},
      :op => {:$not => /测试/}
    }
  },{
    :$group => {
      :_id => {
        :date => {"$substr" => [ {"$add" => ["$paid_at", 8*60*60000]}, 0, 7]},
        :op => '$op',
      },
      :count => {:$sum => 1},
    }
  }
])

send << [ "系统下单 ", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :op.not => /haihuilai/).count,
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :op.not => /haihuilai/).count,
          op.select{|n| n["_id"]["date"] == "2016-11" && ( n["_id"]["op"].match(/haihuilai/) == nil )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2016-12" && ( n["_id"]["op"].match(/haihuilai/) == nil )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-01" && ( n["_id"]["op"].match(/haihuilai/) == nil )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-02" && ( n["_id"]["op"].match(/haihuilai/) == nil )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-03" && ( n["_id"]["op"].match(/haihuilai/) == nil )}.map{|m| m["count"]}.reduce(:+),
]

send << [ "代下单", Booking.where(:paid_at.lt => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :op => /haihuilai/).count,
          Booking.where(:paid_at.gte => Time.parse("2016-11-01"), :review_status.ne => "退单完成", :op => /haihuilai/).count,
          op.select{|n| n["_id"]["date"] == "2016-11" && ( n["_id"]["op"].match(/haihuilai/) )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2016-12" && ( n["_id"]["op"].match(/haihuilai/) )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-01" && ( n["_id"]["op"].match(/haihuilai/) )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-02" && ( n["_id"]["op"].match(/haihuilai/) )}.map{|m| m["count"]}.reduce(:+),
          op.select{|n| n["_id"]["date"] == "2017-03" && ( n["_id"]["op"].match(/haihuilai/) )}.map{|m| m["count"]}.reduce(:+),
]

Emailer.send_custom_file(['yangdong@haihuilai.com','chenyilin@haihuilai.com'],  "采购商运营对比统计数据(201611前后对比)", XlsGen.gen(send), "采购商运营对比统计数据(201611前后对比).xls" ).deliver_now







# 各个城市订单区间统计
#
data = Booking.where(:paid_at.ne => nil, :status.ne => "退单完成").map_reduce(
    %Q{
      function(){
        emit(this.from_city, {count: 1, price: this.total_rmb, profit: this.company_profit});
      }
    },
    %Q{
      function(key, items){

        var r = {count: 0, price: 0, profit: 0}
        items.forEach(function(item){
          r.price += item.price;
          r.profit += item.profit;
          r.count += item.count;
        })
        return r;
      }
    }).out(:inline => true).to_a


# 订单量统计Top 20
count_top = data.sort_by{|n| -n["value"]["count"]}[0,20]


# 成交金额统计Top 20

count_price = data.sort_by{|n| -n["value"]["price"]}[0,20]

# 利润统计Top 20
count_profit = data.sort_by{|n| -n["value"]["profit"]}[0,20]



top_city_count = count_top.map{|n| n["_id"]}[0,10]


# 订单量统计前三城市成交金额 每一百区间范围内订单数量统计
top_data = Booking.where(:paid_at.ne => nil, :from_city.in => top_city_count, :status.ne => "退单完成", :type.in => [/接/, /送/ ]).map_reduce(
    
    %Q{
      function(){
        var city = this.from_city;
        var price = this.total_rmb;
        var span = parseInt(price/100)
        //emit({city: city, span: span, price: price}, {count: 1})
        emit({city: city, span: span}, {count: 1})
      }
    },
    %Q{
      function(key, items){
        var r = {count: 0};
        items.forEach(function(item){
          r.count += item.count;
        })
        return r;
      }
    }).out(:inline => true).to_a




# 历史订单量前十城市成交金额100区间订单数量统计

top_res = [["城市", "区间", "金额起点", "订单数量"]]
top_data.each do |n|
  span = (n["_id"]["span"]*100).to_i
  top_res << [n["_id"]["city"], [span, span+100 ], span , n["value"]["count"].to_i]
end


# 历史订单量Top20城市

top_count_send = [["历史订单Top20城市"],["城市", "订单量"]]

count_top.each do |n|
  top_count_send << [n["_id"], n["value"]["count"].to_i]
end

top_price_send = [["历史成交Top20城市"],["城市", "成交金额"]]

count_price.each do |n|
  top_price_send << [n["_id"], n["value"]["price"].round(2)]
end

top_profit_send = [["历史利润Top20城市"], ["城市", "利润总计"]]
count_profit.each do |n|
  top_profit_send << [n["_id"], n["value"]["profit"].round(2)]
end


Emailer.send_custom_file(['yangdong@haihuilai.com','chenyilin@haihuilai.com', 'wubo@haihuilai.com'],  "历史Top10成交量城市成交金额区间统计数据", XlsGen.gen(top_res, top_count_send, top_price_send, top_profit_send), "Top10城市成交金额范围统计.xls" ).deliver_now




### 历史所有待确认工单数据


send = [["ID", "创建时间", "更新时间", "采购商", "供应商", "BD", "订单类型", "国家", "城市", "起始时间", "结束时间", "人数", "车型", "司导", "当地价格", "人民币价格"]]
PriceTicket.where(:status => "待确认").each do |n|
  send << [n.id, n.created_at.to_date.to_s, n.updated_at.to_date.to_s, n.consumer_name, n.supplier_name, n.admin_user, n.booking_type, n.try(:country), n.try(:city), n.from_date, n.end_date, n.people_num, n.car_model, n.driver_category, n.local_price, n.price]
end


Emailer.send_custom_file(['yangdong@haihuilai.com'],  "历史待确认工单统计", XlsGen.gen(send), "待确认工单数据.xls" ).deliver_now
