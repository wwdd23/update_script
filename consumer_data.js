Booking.where()


res = Booking.collection.aggregate([
  {
    :$match => {
      :paid_at => {:$ne => nil},
      :op => {:$nin => [/测试/]}
    }
  },
  {
    :$group => {
      #:_id => {:type => '$type', :city_id => '$from_location_id'},
      :_id => {:cusumer_name => '$consumer_name', :company => '$consumer_company', :is_child => '$manager_id'},
      :sub_price => {'$sum' => '$total_rmb'},
      :count => {'$sum' => 1},
    }
  }
])


send_out = [["采购商注册名", "采购商名称", "支付金额", "订单数量"]]

res.each do |n|

  send_out <<  [n["_id"]["cusumer_name"], n["_id"]["company"], n["sub_price"], n["count"]]

end

Emailer.send_custom_file(['zhaiyangdong@haihuilai.com','huyuzhuo@haihuilai.com'],  "采购商商家历史数据", XlsGen.gen(send_out), "采购商商家数据.xls" ).deliver




# 理论上为上一个月的流水
span = Time.now.beginning_of_mouth..Time.now.end_of_month

a = Booking.where(:created_at => span, :paid_at.ne => nil, :op.not => /测试/, :status.ne => "退单成功").map_reduce(
  %Q{
    function(){
      var consumer_company = this.consumer_company;
      var sell_name = this.sell_name; 
      var price = this.total_rmb;
      var profit = this.company_profit; //利润
      emit({consumer: consumer_company, sell_name: sell_name}, { price: price, profit: profit, count: 1 });
    }
  },
  %Q{
    function(key, items){

      var r = {price: 0, profit: 0, count: 0}
      items.forEach(function(item){
        r.price += item.price;
        r.profit += item.profit;
        r.count += item.count;
      })
      return r;
    }
  }).out(:inline => true)
