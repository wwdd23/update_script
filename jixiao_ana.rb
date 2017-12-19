# 
span = Time.parse("2017-11-01")..Time.parse("2017-12-01")

other_type = ["门票", "酒店", "餐费", "其他垫付"]


Booking.where(:back_booking_type.ne => nil, :back_booking_type.nin => other_type).map(&:back_booking_type)

Booking.where(:paid_at => span, :back_booking_type.nin => other_type, :status => /退/)

# 当月下单支付的接送机；包车；API的订单（不包括门票；酒店；餐；当地签单；杂费等）
Booking.where(:paid_at => span, :back_booking_type.nin => other_type, :status.nin => [/退/]).count


#2. 当月内所有申请退款及退款完成状态的订单全部不计算在内；
Booking.where(:request_cancel_at=> span, ).count




paid_id = Booking.where(:paid_at => span).map(&:id);nil

request_id = Booking.where(:request_cancel_at=> span, ).map(&:id); nil

all_id = (paid_id + request_id).uniq;nil


out = [["订单号", "采购商", "BD", "支付时间", "申请退款时间", "退款时间", "订单类型", "金额", "利润", "出发国家", "出发城市", "订单状态", "备注类型"]] 
Booking.where(:id.in => all_id).each do |n|

  out << [n.booking_param, n.consumer_company, n.sell_name, n.paid_at.to_date, (n.request_cancel_at.present? ? n.request_cancel_at.to_date: nil), 
          (n.cancelled_at.present? ? n.cancelled_at.to_date: nil), n.type, n.total_rmb.round(2), n.company_profit.round(2), n.from_country, n.from_city, n.status, n.back_booking_type
  ]


end


Emailer.send_custom_file(['wudi@haihuilai.com'], "201711月订单详情", XlsGen.gen(out), "201711月订单详情.xls").deliver_now

span = Time.parse("2017-06-01")..Time.parse("2017-11-01")


Booking.where(:paid_at => span).each do |n|
  out << [n.booking_param, n.consumer_company, n.sell_name, n.paid_at.to_date, (n.request_cancel_at.present? ? n.request_cancel_at.to_date: nil), 
          (n.cancelled_at.present? ? n.cancelled_at.to_date: nil), n.type, n.total_rmb.round(2), n.company_profit.round(2), n.from_country, n.from_city, n.status, n.back_booking_type
  ]
end
Emailer.send_custom_file(['wudi@haihuilai.com'], "20176~10月订单详情", XlsGen.gen(out), "20176~10月订单详情.xls").deliver_now



span = Time.parse("2017-11-01")..Time.parse("2017-12-01")
Consumer.where(:review_status => "审核通过", :reviewed_at => span,:manager_id => nil ).count
Consumer.where(:review_status => "审核通过", :reviewed_at => span,:manager_id.ne => nil ).count


