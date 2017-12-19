
out = [["订单号", "类型", "订单状态", "订单开始", "订单结束", '行程']]
Booking.where(:paid_at.ne => nil, :type => /包车/).each do |n|

  out << [
    n.booking_param,
    n.type,
    n.status,
    n.from_city,
    n.to_city,
    n.travel_items_location,
  ]
end

Emailer.send_custom_file(['yangsi@haihuilai.com'],  "包车订单路径信息", XlsGen.gen(out), "包车订单路径信息.xls" ).deliver

out = [["订单号","采购商", "订单类型", "结算方式", "支付时间", "金额", "订单状态"]]
Booking.where(:paid_at => Time.parse("2016-01-01")..Time.now).each do |n|
  out << [n.booking_param, n.consumer_company, n.type, n.payment_type, n.paid_at.to_date, n.total_rmb, n.status]
end



# 订单备注信息统计
#
out = [["订单号", "采购商", "支付时间", "订单类型", "大区", "城市", "订单状态", "订单备注", ]]
Booking.where(:private_memo.ne => nil).each do |n|

  m = n.private_memo
  if m.match(/</)
    p = m.gsub("<","").gsub("<","").gsub(">", "").gsub("/", "")
  else
    p = m
  end


  out << [n.booking_param, n.consumer_company, n.paid_at, n.type, n.zone, n.from_city, n.status, p]
end


 Booking.where(:booking_param => 1193172170).first.private_memo.gsub("<")


out = [["id", "公司名称", "注册人", "审核通过时间", "账号类型", "销售"]]
Consumer.where(:review_status => "审核通过",:reviewed_at => 1.month.ago..Time.now).each do |n|
  out << [n.id , n.company_name, n.fullname,  n.reviewed_at.to_date, (n.manager_id.present? ? "子账号": "主账号"), n.admin_user]
end

#接机举牌信息
out = [["订单号", "开始时间", "留言信息"]]
Booking.where(:type => "接机",:paid_at.ne => nil).each do |n|

  out << [n.booking_param, n.start_date.to_date, n.memo]

end
