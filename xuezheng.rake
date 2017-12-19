## 接送机时间统计

a = Booking.where(:created_at => Time.parse("2016-07-01")..Time.parse("2017-07-01"), :paid_at.ne => nil, :type => /机/)

out = [["订单号", "订单类型", "下单日期", "支付日期", "订单状态", "采购商", "供应商", "国家", "起始城市", "机场", "航班号", "接/送机时间"  ]]


a.each do |n|

  airport = n.pickup_airport.present? ? n.pickup_airport : n.drop_off_airport
  time = n.pickup_time.present? ? n.pickup_time : n.drop_off_time
  flight = n.pickup_flight.present? ? n.pickup_flight : n.drop_off_flight
  out << [n.booking_param, n.type, n.created_at.to_date, n.paid_at.to_date, n.status, n.consumer_company, n.supplier_name, n.from_country, n.from_city, airport, flight, time]

end


Emailer.send_custom_file(['wangxuezheng@haihuilai.com', "jinxue@haihuilai.com"],  "201607~201707接送机订单信息", XlsGen.gen(out), "201607~201707接送机订单信息.xls" ).deliver



a = Booking.where(:paid_at.ne => nil, :status.ne => "退单完成").map_reduce(
  %Q{
    function(){
      var day = new Date(this.paid_at * 1 + 1000 * 3600 * 8);
      if (parseInt(day.getMonth() + 1) >= 10) {
        month = (day.getMonth() + 1)
      } else {
        month = "0" +  (day.getMonth() + 1)
      }

      if (parseInt(day.getDate() + 1) >= 10) {
        d = (day.getDate() + 1)
      } else {
        d = "0" +  (day.getDate() + 1)
      }
      var date = day.getFullYear() + "-" + month + "-" + d;
      emit( date, {count: 1})
    }
  },
    %Q{
    function(key,items) {
      var r = {count: 0}
      items.forEach( function(item){
        r.count += item.count;
      }
      );
      return r;
    }
  },
).out(:inline => true).to_a


out = [["日期", "单量"]]
a.select{|n| n["value"]["count"] >= 100}.each do |n|
  out << [n["_id"], n["value"]["count"]]
end

Emailer.send_custom_file(['wangxuezheng@haihuilai.com'],  "历史成交订单量大于100日期统计", XlsGen.gen(out), "历史成交订单量大于100日期统计.xls" ).deliver
