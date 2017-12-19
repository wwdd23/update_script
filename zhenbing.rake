a = Booking.all.map do |n|
  n.try(:consumer).try(:company_name)
end.uniq


send = [["日期", "采购商公司名称", "提交订单量", "成交订单量", "总流水", "登录次数"]]
[2015, 2016].each do |n|
  (1..12).each do |m|
    a.each do |x|
      Booking.joins(:consumer).where(:consumer.company_name => "森林国际旅行社")
    end
  end
end






Consumer,h
Booking.collection.aggregate([
  {
    :$match => {
      :paid_at => {:$ne => nil},
      :referral => {:$ne => nil} 
    }
  },
  {
    :$group => {
      :_id => '$referral' ,
      :paid_count => {'$sum' => '$number_night_count'},
      :paid => {'$sum' => '$full_price'},
      :paid_order => {'$sum' => 1}
    }
  }
])


consumers = CSV.read('db/consumer_suppliers.csv')






send_out = [ ["采购商ID", "采购商名称", "总流水", "供应商"]]
consumers.each do |n|
  suppliers = n[3]
  rmb_total = n[2].to_i
  if suppliers != "[]"
    p suppliers
    suppliers = suppliers[1..-2]
    ss = suppliers.split(",")

    name = []
    ss.each do |s|
      name << Supplier.where(:id => s.to_i).first.try(:fullname)
    end
      send_out << [
        n[0].to_i,
        n[1],
        n[2].to_f,
        n[3],
        name,
      ]
  end
end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "采购商供应商历史关联数据", XlsGen.gen(send_out), "采购商供应商历史关联数据.xls" ).deliver





booking = Booking.where(:created_at => Time.parse("2016-10-21")..Time.parse('2016-11-25')).where(:op.not => /测试/)

send = [["下单时间", "支付时间" , "采购商", "供应商", "下单人", "销售", "op", "订单金额", "订单类型", "订单状态", "开始日期", "结束日期", "区域", "城市"]]


booking.each do |n|
  p n.id
  send << [
    n.created_at.to_date.to_s,
    n.paid_at.present? ? n.paid_at.to_date.to_s : nil,
    n.consumer.present? ? n.consumer.company_name : nil,
    n.try(:supplier_name),
    n.try(:creater_name),
    n.sell_name,
    n.op,
    n.total_rmb,
    n.type.present? ? "接送机" : "标准用车",
    n.status,
    n.from_date.to_date.to_s,
    n.to_date.to_date.to_s,
    n.zone,
    n.from_location.name_cn,
  ]

end

Emailer.send_custom_file(['zhengbin@haihuilai.com'],  "20161021-1124订单历史数据", XlsGen.gen(send), "20161021-1124订单数据.xls" ).deliver




# 车导审核预警
# 车导已激活数量 车导未激活数量  
#  
@reved = Supplier.where(:type_cn => "车导", :review_status_cn => '审核通过')
@refused = Supplier.where(:type_cn => "车导", :review_status_cn => '审核不通过')
@inactive = Supplier.where(:type_cn => "车导", :review_status_cn => '未激活')
@pending = Supplier.where(:type_cn => "车导", :review_status_cn => '待审核')

@all_count = Supplier.where(:type_cn => "车导").count

def get_ratio(d1, d2)
  return 0 if d2.to_f == 0

  (d1.to_f / d2.to_f * 100).round(2)
end

@reved_rate = "#{Storage::Base.get_ratio( @reved.count, @all_count)}%"
@refused_rate = "#{Storage::Base.get_ratio( @refused.count, @all_count )}%"
@inactive_rate = "#{Storage::Base.get_ratio( @inactive.count, @all_count)}%"
@pending_rate = "#{Storage::Base.get_ratio( @pending.count, @all_count)}%"


# 供应商用车数量统计  明英
#

a = Booking.collection.aggregate([
  {:$match => {:consumer_name => {:$not => /测试/}, :paid_at => {:$ne => nil}}},
  {:$group => {
    :_id => {:supplier_id => '$supplier_id', :supplier_name => '$supplier_name'},
    :order_count => {'$sum' => 1}, 
    :price_count => {'$sum' => '$total_rmb'}
    }
  }
])

#订单数量Top30
order = a.sort{|a,b| b["order_count"] <=> a['order_count']}[0,30]

#订单金额Top30
price = a.sort{|a,b| b["price_count"] <=> a['price_count']}[0,30]

order_by_id = order.map{|x| [x["_id"]["supplier_id"], x["order_count"] ]}
price_by_id = price.map{|x| [x["_id"]["supplier_id"], x["price_count"]]}



f = Booking.where(:supplier_id => 333, :paid_at.ne => nil)

1. 获取所有订单中起始日期区间  所有日期

2. 遍历所有日期区间，每日有出现订单数统计


# 1
date_all = f.map{|n| (n.from_date..n.to_date).map{|x| x.to_s}}.flatten.uniq

# 2 
date_all.map do |n|
  date = Time.parse(n)
  f.where(:from_date.gte => date, :to_date.gte => date).count
end


def a_count
  k=Hash.new(0)
  self.each{|x| k[x]+=1}
  k
end


send_order = [["供应商ID", "供应商名称", "订单总量", "账号","数量"]]
#send_price = [["供应商ID", "供应商名称", "订单总金额", "账号","数量"]]
order_by_id.each do |data|
#price_by_id.each do |data|
  f = Booking.where(:supplier_id => data[0], :paid_at.ne => nil)

  date_all = f.map{|n| (n.from_date..n.to_date).map{|x| x.to_s}}.flatten.uniq

  car_count = date_all.map do |n|
    f.where(:from_date.lte => n.to_date, :to_date.gte => n.to_date).count
  end

  out = car_count.a_count

  supplier = Supplier.where(:id => data[0]).first

  #send_price << [data[0], supplier.try(:fullname), data[1].to_i, supplier.try(:email), out]
  send_order << [data[0], supplier.try(:fullname), data[1].to_i, supplier.try(:email), out]
  

end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "供应商用车量统计", XlsGen.gen(send_order, send_price), "供应商用车量统计.xls" ).deliver



# 成交订单中有多少是来源于工单
#
def ratio_pt_booking(span )


  span = Time.parse("2017-07-01")..Time.parse("2017-08-01")
  pt_ids = []
  all_booking = Booking.where(:paid_at => span, :sell_name => "张海英", :price_ticket_ids.ne => [])
  all_booking.each{|n| n.price_ticket_ids.each{|m| pt_ids<< m}}
  in_pt_count = PriceTicket.where(:created_at => span, :id.in => pt_ids).count
  ratio = Storage::Base.get_ratio( in_pt_count, PriceTicket.where(:sell_name => "张海英", :created_at => span).count)
  return [in_pt_cout, ratio]
end
