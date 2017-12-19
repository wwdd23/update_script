out = [["采购商id", "采购商公司", "采购商注册人", "支付类型", "结算日期", "结算规则"]]
Consumer.where(:payment_type.in => ["月结", "周结"], :review_status => "审核通过" ).each do |n|
  out << [n.id, n.company_name, n.fullname, n.payment_type, ]

end

Emailer.send_custom_file(['hanguang@haihuilai.com', 'fengyu@haihuilai.com'],  "周期账单采购商结算基础信息", XlsGen.gen(out), "周期账单采购商结算基础信息.xls" ).deliver




day = (ENV['date']|| Time.now).to_date
filter = ({:manager_id => nil, :fullname.not => /测试/, :review_status => "审核通过"})
filter = filter.merge!({:payment_type => "月结"})
title = "月结"
date_s = "end_of_month"
key_date = day.prev_month.beginning_of_month.to_s
consumer = Consumer.where(filter)
consumer_ids = consumer.map(&:id)


send_out = [["采购商", "订单金额", "实际支付金额",  "已结金额", "未结金额", "退款金额"]]
consumer_ids.each do |id|
  api_data = Storage::Fetcher.get_account_balance({:consumer_ids => id})
  all_booking_id = api_data["result"].map{|n| n.values.map{|x| x.values.map{|w|  w.map{|m| m["booking_id"]}}}}.flatten
  all_booking = Booking.where(:booking_param.in => all_booking_id)
  booking_consumer = Consumer.where(:id => id).first

  out = []
  api_data["result"].each do |res|
    res.each do |x,y|
      y.each do |n,m|
        out.concat(m)
      end
    end
  end

  #订单金额

  price = all_booking.map{|n| n["total_rmb"]}.reduce(:+)
  #已结金额
  basic_consumer_real_payment = out.map{|n| n["basic_consumer_real_payment"]}
  settlement_amount = out.map{|n| n["settlement_amount"]}
  #未结金额
  remain_settlement_amount = out.map{|n| n["remain_settlement_amount"]}
  #退款金额
  cancel_price = out.map{|n| n["cancel_price"]}
  send_out << [booking_consumer.company_name, 
               price.to_f,
               basic_consumer_real_payment.present? ? basic_consumer_real_payment.reduce(:+).to_f : 0, 
               settlement_amount.present? ? settlement_amount.reduce(:+).to_f : 0, 
               remain_settlement_amount.present? ?  remain_settlement_amount.reduce(:+).to_f : 0,
               cancel_price.present? ? cancel_price.reduce(:+).to_f : 0
  ]
end




send_out_e = [["采购商", "BD", "订单金额", "实际支付金额",  "已结金额", "未结金额", "退款金额"]]
consumer_ids.each do |id|
  api_data = Storage::Fetcher.get_account_balance({:consumer_ids => id})
  all_booking_id = api_data["result"].map{|n| n.values.map{|x| x.values.map{|w|  w.map{|m| m["booking_id"]}}}}.flatten
  all_booking = Booking.where(:booking_param.in => all_booking_id)
  booking_consumer = Consumer.where(:id => id).first

  bd = booking_consumer.admin_user
  data = api_data["result"].first

  next send_out_e << [booking_consumer.company_name, 0, 0, 0, 0, 0] if data.values.first.select{|n| n["2017-06-01"]}.blank?

  out = []
  p id

#  p  data.values.select{|n| n["2017-06-01"]}
  data.values.first.select{|n| n["2017-06-01"]}.each do |x,y|
    out.concat(y)
  end

  p out
  #订单金额
  price = all_booking.map{|n| n["total_rmb"]}.reduce(:+)
  #已结金额
  basic_consumer_real_payment = out.map{|n| n["basic_consumer_real_payment"]}
  settlement_amount = out.map{|n| n["settlement_amount"]}
  #未结金额
  remain_settlement_amount = out.map{|n| n["remain_settlement_amount"]}
  #退款金额
  cancel_price = out.map{|n| n["cancel_price"]}
  send_out_e << [booking_consumer.company_name, bd,
               price,
               basic_consumer_real_payment.present? ? basic_consumer_real_payment.reduce(:+) : 0, 
               settlement_amount.present? ? settlement_amount.reduce(:+) : 0, 
               remain_settlement_amount.present? ?  remain_settlement_amount.reduce(:+) : 0,
               cancel_price.present? ? cancel_price.reduce(:+): 0
  ]
end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "周期账单采购商结算汇总信息", XlsGen.gen(send_out, send_out_e), "周期账单采购商结算汇总信息.xls" ).deliver_now




booking = Booking.where(:paid_at => Time.parse("2017-01-01")..Time.now, :status.ne => "退单完成",:consumer_company.nin => [ /测试/] )


out = [["订单号", "类型", "月度", "采购商", "支付时间", "开始日期", "供应商", "采购价", "供应价"]]


booking.each do |n|

  out << [n.booking_param, n.type, n.paid_at.strftime("%Y-%m"), n.consumer_company, n.paid_at.to_date.to_s, n.from_date.to_date.to_s, n.supplier_name, n.total_rmb, n.supplier_total_rmb]

end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "上半年历史订单信息", XlsGen.gen(out), "上半年历史订单信息.xls" ).deliver_now




zones = Booking.all.map(&:zone).uniq

out = [["区域", "支付时间", "月份", "支付金额" , "成本", "人数", "订单状态", "类型"]]

Booking.where(:paid_at => Time.parse("2016-01-01")..Time.parse("2018-01-01"),:status.nin => [/退/]).each do |n|
  out << [n.zone, n.paid_at.year, n.paid_at.month,  n.total_rmb, n.supplier_total_rmb, n.people_num, n.status, n.type]
end



Emailer.send_custom_file(['hanguang@haihuilai.com'],  "2016-2017成本订单统计-add_month_type_paid", XlsGen.gen(out), "2016-2017成本订单统计—add_month_type_paid.xls" ).deliver_now




out =[["单号", "下单时间",  "支付时间", "订单状态", "采购商", "供应商", "出发国家", "出发城市", "出行日期", "结束时间", "类型", "采购金额", "采购本币金额", "供应金额", "供应本币金额",  "币种",  "汇率", "利润"]]
Booking.where(:paid_at => Time.parse("2015-01-01")..Time.parse("2017-12-01"), :consumer_company.nin => [/测试/]).each do |n|


  currency_name = n.try(:from_location).ancestors.where(:currency_id.ne => nil).first.try(:currency).try(:name_cn)
  out << [n.booking_param, n.created_at.to_date, n.paid_at.to_date, n.status, n.consumer_company, n.supplier_name, n.from_country, n.from_city, n.from_date.to_date,  n.to_date.to_date, n.type,
          n.total_rmb, n.total_original_currency, n.supplier_total_rmb, n.supplier_locale_price, currency_name, n.conversion_rate, n.company_profit]
end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "历史订单基础信息", XlsGen.gen(out), "历史订单基础信息.xls" ).deliver_now


# 采购商全量信息
#
c_out = [["采购商名称", "注册人信息", "注册时间", "审核时间", "BD", "账号类型", "支付方式", "状态"]]
Consumer.where(:created_at => Time.parse("2015-01-01")..Time.parse("2017-12-01")).each do |n|
   channel = n.try(:manager_id).present? ? "子账号" : "主账号"
   c_out << [n.company_name, n.fullname, n.created_at , n.reviewed_at, n.admin_user, channel, n.payment_type, n.review_status]
end

# 供应商信息
#
s_out = [["姓名", "身份", "车队", "注册时间", "审核时间", "状态"]]

Supplier.where(:created_at =>  Time.parse("2015-01-01")..Time.parse("2017-12-01")).each do |n|
  s_out << [n.fullname, n.type_cn, n.team_name, n.created_at.to_date, n.reviewed_at, n.review_status_cn]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "采购/供应商基础信息", XlsGen.gen(c_out, s_out), "采购供应商信息.xls" ).deliver_now
