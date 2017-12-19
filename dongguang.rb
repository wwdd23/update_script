
out = [["订单号", "采购商", "采购价", "供应价", ]]

Booking.where(:price_ticket_ids.nin => [[],nil],:paid_at => Time.parse("2017-02-01")..Time.now).each do |n|
    out << [n.booking_param, n.consumer_company, n.total_rmb, n.supplier_price, ]
end

outa = [["订单号", "采购商", "采购价", "供应价", "利润"]]
Booking.where(:price_ticket_ids.nin => [[],nil],:paid_at => Time.parse("2017-02-01")..Time.now, :booking_param.nin => x).each do |n|
    outa << [n.booking_param, n.consumer_company, n.total_rmb, n.supplier_price, n.company_profit]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "2月至今成交订单统计_移除标准订单影响", XlsGen.gen(out,outa), "2月至今成交订单统计_移除标准订单影响.xls" ).deliver_now


all_booking_ids = Booking.where(:price_ticket_ids.nin => [[],nil],:paid_at => Time.parse("2017-02-01")..Time.now).map(&:booking_param).uniq




PriceTicket.where(:created_at =>  Time.parse("2017-02-01")..Time.now).last.booking_params


# 移除标准订单影响
array = []
a = PriceTicket.where( :booking_type.ne => "非标订单").map(&:booking_params);nil
a.each do |n|
  array.concat(n)
end;nil

x = []
array.each do |n|
  x << n.to_i
end;nil

outa = [["订单号", "采购商", "采购价", "供应价", "利润"]]
Booking.where(:price_ticket_ids.nin => [[],nil],:paid_at => Time.parse("2017-02-01")..Time.now, :booking_param.nin => x).each do |n|
    outa << [n.booking_param, n.consumer_company, n.total_rmb, n.supplier_price, n.company_profit]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "2月至今成交订单统计_移除标准订单影响", XlsGen.gen(out,outa), "2月至今成交订单统计_移除标准订单影响.xls" ).deliver_now


## 区域销售 利润统计 隔周五 6点执行
consumer = Consumer.where(:manager_id => nil, :review_status => "审核通过", :email.nin => [/cn\.org/,/com\.org/,/net\.org/], :company_name.nin => [/测试/,/趣玩贝/,/还会来/]).map(&:company_name).compact.uniq;nil


out = [["责任BD", "采购商名称", "最后登录时间", "最后下单时间", "历史登录次数", "利润率"]]
consumer.each do |n|
  c = Consumer.where(:company_name => n, :review_status => "审核通过", :email.nin => [/cn\.org/,/com\.org/,/net\.org/])
  b = Booking.where(:paid_at => Time.parse("2017-05-08")..Time.parse("2017-06-09"), :consumer_company => n, :status.ne => "退单完成")
  last_time = c.map{|m| m.try(:last_sign_in_at)}.compact.max
  all_booking_paid_time = b.map{|m| m.paid_at}
  last_paid_time = all_booking_paid_time.present? ? all_booking_paid_time.sort.last : nil
  all_sign_in_count = (c.map(&:sign_in_count).compact.reduce(:+))
  if b.count == 0
    tmp = "3%"
  else
    tmp = nil
  end

  p n
  out << [c.first.admin_user, n, last_time, last_paid_time, all_sign_in_count, tmp]
end;nil


Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "利润加价表_HHL_#{Time.now.to_date.to_s}", XlsGen.gen(out), "利润加价表_HHL_#{Time.now.to_date.to_s}.xls" ).deliver_now


day = (ENV['date']|| Time.now).to_date

week_step = day.strftime("%W").to_i
if (( week_step % 2 ) == 1)
  ## 区域销售 利润统计 隔周五 6点执行
  consumer = Consumer.where(:manager_id => nil, :review_status => "审核通过", :email.nin => [/cn\.org/,/com\.org/,/net\.org/], :company_name.nin => [/测试/,/趣玩贝/,/还会来/]).map(&:company_name).compact.uniq;nil
  out = [["责任BD", "采购商名称", "最后登录时间", "最后下单时间", "历史登录次数", "利润率"]]
  consumer.each do |n|
    c = Consumer.where(:company_name => n, :review_status => "审核通过", :email.nin => [/cn\.org/,/com\.org/,/net\.org/])
    b = Booking.where(:paid_at => Time.parse("2017-05-08")..Time.parse("2017-06-09"), :consumer_company => n, :status.ne => "退单完成")
    last_time = c.map{|m| m.try(:last_sign_in_at)}.compact.max
    all_booking_paid_time = b.map{|m| m.paid_at}
    last_paid_time = all_booking_paid_time.present? ? all_booking_paid_time.sort.last : nil
    all_sign_in_count = (c.map(&:sign_in_count).compact.reduce(:+))
    if b.count == 0
      tmp = "3%"
    else
      tmp = nil
    end
    p n
    out << [c.first.admin_user, n, last_time, last_paid_time, all_sign_in_count, tmp]
  end;nil
  Emailer.send_custom_file(['wudi@haihuilai.com'],  "利润加价表_HHL_#{day.to_s}", XlsGen.gen(out), "利润加价表_HHL_#{day.to_s}.xls" ).deliver_now

end

