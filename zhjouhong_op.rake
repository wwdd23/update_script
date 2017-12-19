ids =.map(&:id)


out = [["公司名称", "公司地址", "电话", "邮箱", "状态", "登陆次数", "成单量", "成单金额"]]
Consumer.where(:company_address => /浙江/).each do |n|
  id = n.id
  order = Booking.where(:consumer_id => id,:paid_at.ne => nil,:status.ne => '退单完成')
  out << [n.company_name, n.company_address, n.phone, n.email, n.review_status, n.try(:sign_in_count), n.try(:last_sign_in_at), order.count, order.map(&:total_rmb).reduce(:+)]
end

Emailer.send_custom_file(['zhouhong@haihuilai.com'],  "浙江采购商信息", XlsGen.gen(out), "浙江采购商信息.xls" ).deliver


out = [["公司名称", "责任BD",  "状态", "登陆次数", '最后登陆次数', "成单量", "成单金额"]]
Consumer.where(:admin_user => "周伍骏",:manager_id => nil).each do |n|
  id = n.id
  ids = Consumer.where(:manager_id => id,:review_status => "审核通过").map(&:id)
  ids.push(id)
  p ids
  order = Booking.where(:consumer_id.in => ids,:paid_at.ne => nil, :status.ne => "退单完成")
  order_count = order.count
  total_price = order.map(&:total_rmb).reduce(:+)

  out << [n.company_name, n.admin_user, n.review_status, n.try(:sign_in_count), n.try(:last_sign_in_at), order_count, total_price]

end


Emailer.send_custom_file(['zhouwujun@haihuilai.com', 'chenyilin@haihuilai.com'],  "周伍骏采购商交接需求数据", XlsGen.gen(out), "周伍骏采购商交接需求数据.xls" ).deliver
