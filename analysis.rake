#计算利润率
#
a =  [63780.34, 3863.26, 110785.31, 79408.5, 83180.1, 138293.0, 174685.62, 17196.13]


b = [1145.0, 1674.22, 12524.5, 30519.0, 50502.0, 14702.66, 76424.8, 63499.0, 23035.71, 7464.7, 48183.29, 79431.99]


c = b + a


# 计算利润率变化
def growth_rate(data)
  x = []
  (0..(data.count - 1)).each do |n|
    if n - 1 >= 0
      x << (data[n] == 0 ? 0 : (data[n].to_f - data[n-1].to_f) / data[n].to_f * 100).round(2)
    else
      x << 0
    end
  end

  out1 = x[0..11]
  out2 = x[12..24]
  return [out1, out2]
end




Booking.where(:paid_at => Time.parse("2017-07-01")..Time.parse("2017-08-01"), :sell_name => "刘燕", :status.ne => "退单完成")



### 采购商历史利润率分析
#
span_o = Time.parse("2016-01-01")..Time.parse("2017-01-01")
span_n = Time.parse("2017-01-01")..Time.parse("2018-01-01")

out = [["ID", "采购商", "BD", "16年成交额", "16年利润", "16年利润率", "17年成交额", "17年利润", "17年利润率", 
        "16接送机成交", "16接送机利润", "16年接送机利润率", 
        "16包车成交", "16包车利润", "16年包车利润率", 
        "16精品成交", "16精品利润", "16年精品线路利润率", 
        "17接送机成交", "17接送机利润", "17年接送机利润率", 
        "17包车成交", "17包车利润", "17年包车利润率", 
        "17精品成交", "17精品利润", "17年精品线路利润率", ]]

names = Consumer.where(:review_status => '审核通过', :manager_id => nil).map(&:company_name).uniq;nil
names.each do |name|

  #name = consumer.company_name

  consumer = Consumer.where(:company_name => name).first
  sell = consumer.admin_user
  old_order = Booking.where(:paid_at => span_o,:status.nin => [/退/], :consumer_company => name)
  new_order = Booking.where(:paid_at => span_n,:status.nin => [/退/], :consumer_company => name)

  
  o_all_price = old_order.map(&:total_rmb).reduce(:+).to_f
  n_all_price = new_order.map(&:total_rmb).reduce(:+).to_f

  o_all_profit = old_order.map(&:company_profit).reduce(:+).to_f
  n_all_profit = new_order.map(&:company_profit).reduce(:+).to_f

  r_all_new = Storage::Base.get_ratio(n_all_profit, n_all_price)
  r_all_old = Storage::Base.get_ratio(o_all_profit, o_all_price)

  tmp  = [consumer.id, name, sell, o_all_price, o_all_profit, "#{r_all_old}%", n_all_price, n_all_profit, "#{r_all_new}%"]

  type = [[/接/,/送/], [/包/], ["精品线路"]]
  type_info = []
  type.each do |n|
    tmp_old_order = old_order.where(:type.in => n)
    if tmp_old_order.present?
      profit = tmp_old_order.map(&:company_profit).reduce(:+).to_f
      price = tmp_old_order.map(&:total_rmb).reduce(:+).to_f
      r_old = Storage::Base.get_ratio(profit, price)
      type_info.concat([price, profit, "#{r_old}%"])
    else
      type_info.concat( [ 0, 0, 0,])
    end
  end

  type.each do |n|
    tmp_new_order = new_order.where(:type.in => n)
    if tmp_new_order.present?
      n_profit = tmp_new_order.map(&:company_profit).reduce(:+).to_f
      n_price = tmp_new_order.map(&:total_rmb).reduce(:+).to_f
      r_new = Storage::Base.get_ratio(n_profit, n_price)
      type_info.concat([n_price, n_profit, "#{r_new}%"])
    else
      type_info.concat( [ 0, 0, 0,])

    end
  end

  tmp.concat(type_info)
  p tmp
  out << tmp

end

Emailer.send_custom_file(['wudi@haihuilai.com'], "16~17采购商利润信息统计", XlsGen.gen(out), "new_16~17采购商利润信息统计.xls").deliver_now 


:wq

