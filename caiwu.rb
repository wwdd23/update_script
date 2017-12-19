

# 周期对账单

# 1. 获取所有周期结算主账户 公司名称
# 预估问题， 1. 出现自主账号公司名称不符的情况有可能会遗漏

# 数据核对： 主账号为周期结算的 39个 
company = Consumer.where(:payment_type.in => ["月结", "周结", "半月结"], :company_name.not => /测试/, :manager_id => nil).map(&:id)


#以上公司名称订单中


base = Booking.where(:consumer_company.in => company,:paid_at.ne => nil)



info = [["订单号", '采购商', '结算方式(订单)', '结算方式(采购)', '下单人', '下单时间', '订单开始', '订单结束', '订单金额', '未结金额']]

base.each do |n|

  info << [
    n.booking_param,
    n.consumer_company,
    n.payment_type,
    n.consumer.try(:payment_type),
    n.consumer_name,
    n.created_at.to_date,
    n.from_date.to_date,
    n.to_date.to_date,
    n.total_rmb,
    "",

  ]
end

Emailer.send_custom_file(['wudi@haihuilai.com'],  "月结对账单", XlsGen.gen(info), "月结对账单.xls" ).deliver



## 订单详情数据报表

span = 10.day.ago.to_date..1.day.ago.to_date
send_out = [["订单号", "订单时间", "结算方式", "订单状态", "应收款", "手续费", "实际收入", "未结算金额",
             "收款公司", "收款渠道", "收款日期", "收款金额",
             "收款公司", "收款渠道", "收款日期", "收款金额",
             "收款公司", "收款渠道", "收款日期", "收款金额",
             "收款公司", "收款渠道", "收款日期", "收款金额",
             "收款备注",
             "订单类型", "采购商", "采购地", "开始时间", "结束时间", 
             "供应商",
             "人民币", "外币", "支付时间", "支付公司", "付款银行", 
             "人民币", "外币", "支付时间", "支付公司", "付款银行",
             "人民币", "外币", "支付时间", "支付公司", "付款银行",
             "人民币", "外币", "支付时间", "支付公司", "付款银行",
             "付款合计", 
             "利润",
             "付款备注", 
             "发票",
             "外汇"
]]


Booking.includes(:transaction, :pay_logs).where(:paid_at => span).each do |n|
   if n.manager_id == nil
     payment_type = n.payment_type
   else
     payment_type = n.parent.payment_type
   end 
  send_out << [
  
    n.booking_param,
    n.paid_at.to_date,
    payment_type,
    n.status,

  
  ]




end

data = Storage::Fetcher.get_booking_info(filter)






