# 月新开账号，每个账号订单量，订单金额， 询价明细
#
# add  sign_in_out sell_name

span = Time.now.beginning_of_month..Time.now.end_of_month
consumers = Consumer.where(:created_at => Time.now.beginning_of_month..Time.now.end_of_month, :review_status => "审核通过")

parent_consumer_id = consumers.where(:manager_id => nil).map(&:id).uniq 
child_consumer_id = consumers.where(:manager_id.ne => nil).map(&:id).uniq

send = [["采购商公司名", '注册时间', '审核通过时间', '订单金额', '销售']]
bookings = Booking.where(:created_at => Time.now.beginning_of_month..Time.now.end_of_month, :paid_at.ne => nil, :op.not => /测试/)

# 主账号订单
p_booking = bookings.where(:consumer_id.in => parent_consumer_id)
c_booking = bookings.where(:consumer_id.in => child_consumer_id)

booking_send = [["订单号", "账号注册时间", "支付时间", "订单金额", "结算方式", "订单类型", "区域", "销售", '开始时间', '结束时间', '车型', '导游级别', "采购商公司名称", "账号属性", "历史登陆次数"]]


ppp =[]
p_booking.each do |n|
  ppp << [
    n.booking_param,
		n.consumer.created_at.to_date.to_s,
    n.paid_at.to_date.to_s,
    n.total_rmb,
		n.payment_type,
		n.type,
		n.zone,
    n.sell_name,

		n["from_date"].to_date.to_s,
		n["to_date"].to_date.to_s,


		n["car_category"],
		n["driver_category"],

    n.try(:consumer).try(:company_name),
    "主账号",
    n.try(:consumer).try(:sign_in_count),
  ]
end
ccc = []
c_booking.each do |n|
  ccc << [
    n.booking_param,
		n.consumer.created_at.to_date.to_s,
    n.paid_at.to_date.to_s,
    n.total_rmb,
    n.payment_type,
		n.type,
		n.zone,
    n.sell_name,
		n["from_date"].to_date.to_s,
		n["to_date"].to_date.to_s,


		n["car_category"],
		n["driver_category"],
    n.try(:consumer).try(:company_name),
    "子账号",
    n.try(:consumer).try(:sign_in_count),
  ]
end
booking_send.concat(ppp)
booking_send.concat(ccc)

Emailer.send_custom_file(['wudi@haihuilai.com'],  "本月新开账号订单统计数据", XlsGen.gen(booking_send), "本月新开账号订单统计数据.xls" ).deliver

parent_consumer_name = consumers.where(:manager_id => nil).map(&:company_name)
child_consumer_name = consumers.where(:manager_id.ne => nil).map(&:company_name)

pt = PriceTicket.where(:created_at => span)
pt_out = [["采购商公司", "工单号", "询价日期", "类型", "经办人", "订单号", "区域" , "国家", "供应商"]]
pt.each do |n|
  location = n.location
  parent_id = n.location.parent_id
  pt_out << [
    n.consumer_name,
    n.id,
    n.created_at.to_date.to_s,
    n.booking_type,
    n.try(:creater).try(:full_name),
    n.booking_params,
    Location.where(:id => parent_id).first.name_cn,
    location.name_cn,
    n.supplier_name,

  ]
end

send = [["采购商公司名", '注册时间', '审核通过时间', '登陆次数' , '销售', '注册类型', '账号类型']]
consumers.where(:company_name.not => /测试/).each do |n|

  send << [
    n.company_name,
    n.created_at.to_date.to_s,
    n.reviewed_at.present? ? n.reviewed_at.to_date.to_s : nil,
    n.sign_in_count,
    n.admin_user,
    n.registration_type,
    n.manager_id.present? ? "子账号" : "主账号"
  ]

end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "本月新开账号订单统计数据", XlsGen.gen(booking_send, pt_out, send), "本月新开账号订单统计数据.xls" ).deliver


id = bookings.map do |n|
 "#{n.booking_param}"
end
(&:booking_param)

p_booking_id = p_booking.map do |n|
 "#{n.booking_param}"
end

c_booking_id = c_booking.map do |n|
 "#{n.booking_param}"
end



pt_send = [['工单号', '订单类型','采购商注册时间', '工单创建时间', '采购商名称', '账号类别', '订单号', '区域', '国家', "供货商"]]
pt.where(:booking_params.in => (p_booking_id + c_booking_id)).each do |n|


  order_id = n.booking_params.first
  order_info = Booking.where(:booking_param => order_id).first
  consumer = order_info.consumer
  consumer_at = consumer.created_at.to_date.to_s

  consumer_name = consumer.company_name
  is_master = consumer.manager_id.present? ? "子账号" : "主账号"

  p n
  location = n.location
  parent_id = n.location.parent_id
  pt_send << [
    n.id,
    n.booking_type,
    consumer_at,
    n.created_at.to_date.to_s,
    consumer_name,
    is_master,
    n.booking_params,
    #n.booking_status.present? ? n.booking_status : nil,
    Location.where(:id => parent_id).first.name_cn,
    location.name_cn,
    n.supplier_name
  
  ]
end
Emailer.send_custom_file(['wudi@haihuilai.com'],  "本月新开账号订单统计数据", XlsGen.gen(booking_send, pt_send, send, pt_out), "本月新开账号订单统计数据.xls" ).deliver





###  周报添加信息

name = ["张海英", "马梦龙", "李骋", "洪瑶", "贺加妮", "王欢", "刘燕"]


Booking.where(:created_at => w_span, :sell_name.in => name, )
d = Time.parse(Time.now.to_date.to_s)
w_span = (Time.parse("18:00", d) - 7.days)..Time.parse("18:00", d)

b = Booking.where(:created_at => w_span)
res = b.collection.aggregate([
  {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
      :paid_at => {:$ne => nil},
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :status => {:$nin => ['退单完成', '订单关闭']},
    }
  },
  {
    :$group => {
      :_id => {
        :sell_name => '$sell_name',
        #:consumer => '$consumer_name',
        :company => '$consumer_id',
      },
      :price_count => {'$sum' => '$total_rmb'}
    }
  }
])


send_out = {}
no_paid = {}
name.each do |name|

  r = res.select{|n| n['_id']["sell_name"] == name }
  send_out[name] ||= [["销售", "采购商ID", "商家名称", "账号属性", "注册用户名", "注册时间", "审核通过时间", "登陆次数", "累计成交额"]]
  no_paid[name] ||= [["销售", name],["注册时间", "审核通过时间", "商家名称", "账号属性", "登陆次数"]]
  r.each do |n|

    key = n["_id"]
    id = key["company"]
    consumer = Consumer.where(:id => id).first

    send_out[name] << [
      key["sell_name"],
      id,
      consumer.company_name,
      consumer.manager_id.present? ? "子账号" : "主账号",
      consumer.fullname,
      consumer.created_at.to_date,
      consumer.try(:reviewed_at).present? ? consumer.try(:reviewed_at).to_date : nil,
      consumer.sign_in_count,
      n["price_count"].round(2),
    ]

  end

  all_id = r.map{|n| n["_id"]["company"]}

  no_paid_booking = Booking.where(:created_at => w_span, :paid_at => nil, :consumers_id.nin => all_id, :sell_name => name)
  no_paid_booking.present? if Consumer.where(:id.in => no_paid_booking.map{|n| n.consumer_id}.uniq).each{|m| no_paid[name] << [m.created_at.to_date, m.try(:reveiwed_at), m.company_name, (m.manager_id.present? ? "子账号" : "主账号"), m.sign_in_count]}


end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "本周销售支付商家统计数据", XlsGen.gen(send_out["张海英"], send_out["马梦龙"], send_out["李骋"], send_out["洪瑶"], send_out["贺加妮"], send_out["王欢"], send_out["刘燕"]), "本周销售支付商家统计数据.xls" ).deliver
Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "本周未支付商家统计数据", XlsGen.gen(no_paid["张海英"], no_paid["马梦龙"], no_paid["李骋"], no_paid["洪瑶"], no_paid["贺加妮"], no_paid["王欢"], no_paid["刘燕"]), "本周未支付商家统计数据.xls" ).deliver



#刘燕统计销售商家统计
#

b = Booking.where(:sell_name => "刘燕")
res = b.collection.aggregate([
 {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
			:paid_at => {:$ne => nil},
			:sell_name => '刘燕',
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :status => {:$nin => ['退单完成', '订单关闭']},
    }
  },
  {
    :$group => {
      :_id => {
        :sell_name => '$sell_name',
        #:consumer => '$consumer_name',
        :company => '$consumer_id',
      },
      :price_count => {'$sum' => '$total_rmb'}
    }
  }
])

send_out = [["销售", "采购商ID", "商家名称", "账号属性", "注册用户名", "注册时间", "审核通过时间", "登陆次数", "累计成交额"]]
no_paid = [["销售", name],["注册时间", "审核通过时间", "注册用户名", "商家名称", "账号属性", "登陆次数"]]
res.each do |n|

    key = n["_id"]
    id = key["company"]
    consumer = Consumer.where(:id => id).first

    send_out << [
      key["sell_name"],
      id,
      consumer.company_name,
      consumer.manager_id.present? ? "子账号" : "主账号",
      consumer.fullname,
      consumer.created_at.to_date,
      consumer.try(:reviewed_at).present? ? consumer.try(:reviewed_at).to_date : nil,
      consumer.sign_in_count,
      n["price_count"].round(2),
    ]
end

sell_id = AdminUser.where(:fullname => "刘燕").first.id

Consumer.where(:admin_user_id => sell_id.first.id,:id.nin => Booking.where(:sell_name => "刘燕", :paid_at.ne => nil,).map(&:consumer_id).uniq ).each do |m|

 no_paid << [m.created_at.to_date, m.try(:reveiwed_at), m.fullname, m.company_name, (m.manager_id.present? ? "子账号" : "主账号"), m.sign_in_count]

end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "本周销售支付商家统计数据", XlsGen.gen(send_out,no_paid), "刘燕历史订单数据.xls").deliver
Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "本周销售支付商家统计数据", XlsGen.gen(no_paid), "刘燕历史订单数据.xls").deliver


# 采购商在线流水排名
consumer_id =  Consumer.all.map(&:id).uniq
#res = Booking.where(:consumer_id.in => consumer_id).collection.aggregate([
#
res = Booking.all.collection.aggregate([
 {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
			:paid_at => {:$ne => nil},
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :status => {:$nin => ['退单完成', '预订单失效', '订单未支付']},
      :consumer_company => {:$not => /测试/}
    }
  },
  {
    :$group => {
      #:_id => '$consumer_id',
      :_id => {:name => '$consumer_company', :type => '$type'},
      :price_count => {'$sum' => '$total_rmb'},
      :order_count => {'$sum' => 1}
    }
  }
])



out = [["采购商", "总流水", "总单数", "接送机流水", "接送机单数", "包车流水", "包车单数"]]
all_name.each do |m|

  aa = res.select{|n| n["_id"]["name"] == m}

  air_info = aa.select{|x| x["_id"]["type"] == "接送机"}.first
  booking_info = aa.select{|x| x["_id"]["type"] == ""}.first

  air_paid = air_info.present? ? air_info["price_count"] : 0
  all_paid = (air_info.present? ? air_info["price_count"] : 0) + (booking_info.present? ? booking_info["price_count"] : 0)
  all_count  = (air_info.present? ? air_info["order_count"] : 0) + (booking_info.present? ? booking_info["order_count"] : 0)
  out << [
    m,
    all_paid,
    all_count,
    air_info.present? ? air_info["price_count"].to_f : 0,
    air_info.present? ? air_info["order_count"] : 0,
    booking_info.present? ? booking_info["price_count"].to_f : 0,
    booking_info.present? ? booking_info["order_count"] : 0
  ]
end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "采购商详细订单数据汇总", XlsGen.gen(out), "采购商详细订单数据.xls",true).deliver

send_paid = [["采购商公司", "累计成交", "订单数"]]

res.each do |n|
  send_paid << [
    n["_id"],
    n["price_count"],
    n["order_count"],
  ]
end

paid_id = res.map{|n| n["_id"]}

no_paid_id = consumer_id - paid_id

no_send = [["采购商公司名称", "采购商ID", "注册名", "账号类型", "创建时间", "审核通过时间", "登陆次数"]]
no_paid_id.each do |n|
  c = Consumer.where(:id => n).first
  p c.try(:fullname)
  p  c.try(:manager_id)

  no_send << [
    c.try(:company_name),
    c.try(:id),
    c.try(:fullname),
    c.try(:manager_id).present? ? "子账号" : "主账号",
    c.try(:created_at).to_date,
    c.try(:reviewed_at).present? ? c.try(:reviewed_at).to_date : nil,
    c.try(:sign_in_count),
  ]
  

end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "采购商订单数据汇总", XlsGen.gen(send_paid, no_send), "采购商订单数据.xls").deliver


send = [["采购商公司", "采购商ID", "注册姓名", "注册时间", "审核通过时间", "累计成交额", "订单量", "登陆次数"]]
res.each do |n|
  id = n["_id"]
  p c.fullname
  send << [
    c.try(:company_name),
    c.try(:id),
    c.fullname,
    c.manager_id.present? ? "子账号" : "主账号",
    c.created_at.to_date,
    c.try(:reviewed_at).present? ? c.try(:reviewed_at).to_date : nil,
    n["price_count"].round(2),
    n["order_count"],
    c.sign_in_count,
  ]
end





#### 采购商数据登陆次数时间
#
Consumer.all.each do |n|
  





end
res = Booking.collection.aggregate([
  {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
      :paid_at => {:$ne => nil},
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :status => {:$nin => ['退单完成', '订单关闭']},
    }
  },
  {
    :$group => {
      :_id => {
        :sell_name => '$sell_name',
        :consumer => '$consumer_company',
        :company => '$consumer_id',
      },
      :price_count => {'$sum' => '$total_rmb'},
      :count => {'$sum' => 1},
      :paid_at_count => {'$push' => "$paid_at"},
      :zone_a => {'$push' => '$zone'},
      :type_a => {'$push' => "$type"}
    }
  }
])

# 计算数组重复字符数量
def a_count
  k=Hash.new(0)
  self.each{|x| k[x]+=1}
  k
end




a = []
x.each do |n,m|
#  a<<[n,m]
  nn = n.clone
 a <<  nn.push(m)
end



out = [["采购商", '销售', '注册时间', '审核通过时间', '最后登陆时间', '最后交易时间', '交易金额', '交易次数', '订单区域', '订单类型']]
res.each do |n|

  sell = n["_id"]["sell_name"]
  id_s = n["_id"]["company"]
  company = n["_id"]["consumer"]

  c = Consumer.where(:id => id_s).first

  type_array = n["type_a"]
  zone_array = n["zone_a"]
  out << [
    company,
    sell,
    c.try(:created_at),
    c.try(:reviewed_at),
    c.try(:last_sign_in_at),
    n["paid_at_count"].max.to_date,
    n["price_count"],
    n["count"],
    zone_array.a_count,
    type_array.a_count,
  ]
end



paid_consumer = res.map{|n| n["_id"]["company"]}.uniq

send_out = [["采购商公司名称", "销售", '注册人', '账号类型', "注册时间", "审核通过时间", "最后登陆时间", "登陆次数"]]
Consumer.where(:id.nin => paid_consumer,:review_status => "审核通过", :company_name.not => /趣玩贝/).each do |n|
  send_out << [
    n.company_name,
    n.admin_user,
    n.fullname,
    n.manager_id.present? ? "子账号" : "主账号",
    n.created_at,
    n.try(:reviewed_at),
    n.try(:last_sign_in_at),
    n.sign_in_count.to_i,
  ]

end



Emailer.send_custom_file(['wudi@haihuilai.com'],  "采购商订单数据", XlsGen.gen(out, send_out), "采购商订单数据.xls" ).deliver

out = {}
a.first["zone_a"].each do |n|
  out[n]+=1
end






PirceTicket.collection.aggregate([
  {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
      #:paid_at => {:$ne => nil},
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :consumer_name => {:$nin => [/测试/]},
    }
  },
  {
    :$group => {
      :_id => {
        :consumer => '$consumer_name',
        :
      }
    }
  }

])


send = [["id", '公司名', '注册月', '销售', '通过时间', '登陆次数', '账号类型', '优惠券使用量', '支付单量', '支付金额']]

(11..12).each do |n|
  start_date = Time.parse("2016-#{n}-01")
  end_date = start_date.end_of_month
  consumers = Consumer.where(:reviewed_at => start_date..end_date )
  consumers.each do |c|
    
    c_id = c.id
    bookings = Booking.where(:paid_at.ne => nil, :consumer_id => c_id )
    send << [
      c_id,
      c.company_name,
      c.reviewed_at.strftime("%Y-%m").to_s,
      c.admin_user,
      c.reviewed_at,
      c.sign_in_count,
      c.manager_id.present? ? "子账号" : "主账号",
      bookings.where(:coupon_id.ne => nil).count,
      bookings.count,
      bookings.map(&:total_rmb).reduce(:+).to_f,
    ]
  end
end


send_out = [["id", "创建时间", "审核通过","公司名称", "注册人", '销售', "电话", "手机", "账号", "账号类型", "支付类型", "登陆次数", "最后登陆时间", "支付订单数", "支付金额","状态"]]
Consumer.where(:op.not => /测试/).each do |n|
  p n
  base = Booking.where(:consumer_id => n.id, :paid_at.ne => nil, :status.nin =>  ['退单完成', '订单关闭'])
  count = base.count
  all_price = base.map(&:total_rmb).reduce(:+)
  send_out << [n.id, n.created_at.to_date, n.try(:reviewed_at).nil? ? nil : n.try(:reviewed_at).to_date, n.company_name, n.fullname, n.admin_user, n.phone, n.mobile,n.email, (n.manager_id.present? ? "子账号" : "主账号"), n.payment_type, n.sign_in_count, n.try(:last_sign_in_at).nil? ? nil : n.last_sign_in_at.to_date, count, all_price , n.review_status]
end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "采购商基本详情", XlsGen.gen(send_out), "采购商基本详情.xls" ).deliver_now
Emailer.send_custom_file(['wudi@haihuilai.com'],  "采购商基本详情", XlsGen.gen(send_out), "采购商基本详情.xls" ).deliver_now


# 金雪名下采购商流水统计
consumer = Consumer.where(:admin_user => "金雪")

book = Booking.where(:sell_name => "金雪",:paid_at.ne => nil, :status.ne => '退单完成')

ids = book.map(&:consumer_id)
out = [["公司名称", "注册人", "自主账号", "订单量", "订单金额"]]
consumer.map(&:id).each do |n|
  c= Consumer.where(:id => n).first
  r = book.where(:consumer_id => n)
  out << [
    c.company_name,
    c.fullname,
    c.manager_id.present? ? "子账号" : "主账号",
    r.present? ? r.count : 0,
    r.present? ? r.map(&:total_rmb).reduce(:+).round(2) : 0
  ]


end









consumer = Consumer.where(:admin_user => "周伍骏")
send_out = [["采购商ID", "公司名称", "注册人", "审核通过时间" ,"账号类型",  "账号", "订单量", "成交金额"]]
#consumer.where(:created_at => Time.parse("2017-02-01")..Time.parse('2017-03-01')).each do |n|
consumer.each do |n|
  id = n["id"]
  r = Booking.where(:created_at => Time.parse("2017-02-01")..Time.parse('2017-03-01'), :paid_at.ne => nil,:status.ne => "退单完成", :consumer_id => id)
  send_out << [
    id, 
    n.company_name,
    n.fullname,
    n.try(:reviewed_at).present? ?  n.try(:reviewed_at).to_date.to_s : n.try(:created_at).to_date.to_s,
    n.manager_id.present? ? "子账号" : "主账号",
    n.fullname,
    r.present? ? r.count : 0,
    r.present? ? r.map(&:total_rmb).reduce(:+).round(2) : 0
  ]
end
Emailer.send_custom_file(['huyuzhuo@haihuilai.com', "luolan@haihuilai.com"],  "本月新开账号订单统计数据", XlsGen.gen(booking_send), "本月新开账号订单统计数据.xls" ).deliver




send = [["采购商", "注册人", "账号类型", "订单号", "支付时间",  "金额", "注册时间", "负责BD", "BD_ID", "Admin_User"]]
Booking.where(:paid_at.ne => nil, :status.ne => "退单完成", :op.not => /测试/).each do |n|
  consumer =  n.consumer_company
  name = n.consumer_name
  paid_at = n.paid_at.to_date
  price = n.total_rmb
  c = n.consumer
  c_created = c.reviewed_at.present? ? c.reviewed_at.to_date : c.created_at.to_date
  type = c.manager_id.present? ? "子账号" : "主账号"

  sell_name = n.sell_name
  sell_id = n.admin_user_id

  send << [ consumer, c.fullname, type, n.booking_param, paid_at, price, c_created, sell_name , sell_id, n.admin_user.try(:fullname)]
end


Emailer.send_custom_file(['zhaiyangdong@haihuilai.com', "chenyilin@haihuilai.com"],  "历史采购商交易订单与效果关联数据", XlsGen.gen(send), "历史采购商交易订单统计数据.xls" ,true).deliver
cunsumer_data.rb:Emailer.send_custom_file(['zhaiyangdong@haihuilai.com','huyuzhuo@haihuilai.com'],  "采购商商家历史数据", XlsGen.gen(send_out), "采购商商家数据.xls" ).deliver

Emailer.send_custom_file(['wudi@haihuilai.com', ],  "采购爬取数据", XlsGen.gen(send), "面膜爬取数据.xls" ).deliver





send = [["订单号", "支付日期", "订单状态", "订单金额"]]
Booking.where(:paid_at => Time.parse('2017-03-01')..Time.parse('2017-04-01'),:sell_name => "洪瑶").each do |n|

  send << [n.booking_param, n.paid_at.to_date, n.status, n.total_rmb]

end
Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "洪瑶3月流水数据", XlsGen.gen(send), "洪瑶3月流水数据.xls" ).deliver





send = [["订单号", "支付日期", "订单状态", "订单金额"]]
Booking.where(:paid_at => Time.parse('2017-03-01')..Time.parse('2017-04-01'),:sell_name => "洪瑶").each do |n|

  send << [n.booking_param, n.paid_at.to_date, n.status, n.total_rmb]

end




# 11月以前所有

Consumer.where(:reviewed_at => {:$lt => Time.parse("2017-04-01")}, :manager_id => nil, :review_status => "审核通过").count
Consumer.where(:reviewed_at => {:$lt => Time.parse("2017-03-01")}, :manager_id => nil, :review_status => "审核通过").count
Consumer.where(:reviewed_at => {:$lt => Time.parse("2017-02-01")}, :manager_id => nil, :review_status => "审核通过").count


Consumer.where(:created_at => {:$lt => Time.parse("2016-11-01")} :manager_id => nil, :review_status => "审核通过").count


# 1月前所有采购商

before_created = Consumer.where(:created_at => {:$lt => Time.parse("2017-01-01")},:reviewed_at.not => {:$gte => Time.parse("2017-01-01")}, :manager_id => nil, :review_status => "审核通过").count

before_created_ids = Consumer.where(:created_at => {:$lt => Time.parse("2017-01-01")},:reviewed_at.not => {:$gte => Time.parse("2017-01-01")}, :manager_id => nil, :review_status => "审核通过").map(&:id);nil

# 1月新增
one = Consumer.where(:reviewed_at => Time.parse("2017-01-01")..Time.parse("2017-02-01"), :manager_id => nil, :review_status => "审核通过").count
one_id = Consumer.where(:reviewed_at => Time.parse("2017-01-01")..Time.parse("2017-02-01"), :manager_id => nil, :review_status => "审核通过").map(&:id);nil

# 2月新增
two = Consumer.where(:reviewed_at => Time.parse("2017-02-01")..Time.parse("2017-03-01"), :manager_id => nil, :review_status => "审核通过").count
two_ids = Consumer.where(:reviewed_at => Time.parse("2017-02-01")..Time.parse("2017-03-01"), :manager_id => nil, :review_status => "审核通过").map(&:id);nil
# 3月新增
three = Consumer.where(:reviewed_at => Time.parse("2017-03-01")..Time.parse("2017-04-01"), :manager_id => nil, :review_status => "审核通过").count
three_ids = Consumer.where(:reviewed_at => Time.parse("2017-03-01")..Time.parse("2017-04-01"), :manager_id => nil, :review_status => "审核通过").map(&:id);nil


[["1月", before_created+one],["2月", before_created_ids+one+two], ["3月", before_created + one + two + three]]


def dups  
  inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys  
end 



(before_created_ids + one_id + two_ids + three_ids).dups

[592, 2083, 2252, 2587, 2720, 2756, 2798, 3548].each do |n|
  p before_created_ids.include?(n)
end






Booking.where(:paid_at => Time.parse('2017-03-01')..Time.parse('2017-04-01'),)

a = Booking.where(:paid_at => Time.parse('2017-03-01')..Time.parse('2017-05-01'),:status.ne => "退单完成",:sell_name.in => [/彩霞/, /梦龙/, /海英/]).map do |n|
  [n.paid_at.strftime('%Y-%m'), n['consumer_company'], n['sell_name']]
end
Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "3-4月BD交易客户统计", XlsGen.gen(a.uniq), "3-4月BD交易客户统计.xls" ).deliver_now




# 2016年-2017年4月采购商流水数据统计
base_consuemr= Consumer.where(:manager_id => nil, :review_status => "审核通过", :company_name.nin => [/测试/, /还会来/, /趣玩贝/])
out = [["销售", "公司名称",  "创建时间",  "注册邮箱",  "注册人",  "电话",  "登陆次数",  "最后登陆时间",  "支付订单数",  "支付金额"]]
base_consuemr.each do |n|
  c_ids = Consumer.where(:manager_id => n.id).map(&:id)
  all_ids = c_ids.push(n.id)
  #all_booking_price = Booking.where(:consumer_id.in => all_ids,:paid_at => Time.parse('2016-01-01')..Time.parse("2017-05-01"),:status.ne => '退单完成').map(&:total_rmb).reduce(:+).to_f.round(2)
  all_booking = Booking.where(:consumer_id.in => all_ids,:paid_at => Time.parse('2016-01-01')..Time.parse("2017-05-01"),:status.ne => '退单完成')
  all_booking_price = all_booking.map(&:total_rmb).reduce(:+).to_f.round(2)
  all_booking_count = all_booking.count
  name = n.company_name
  p name
  #out << [name, all_booking_price]
  base_c = Consumer.where(:id.in => all_ids)
  all_sign_count = base_c.map(&:sign_in_count).compact.reduce(:+)
  sign_in = base_c.map{|n| n.try(:last_sign_in_at)}.compact.sort_by{|n| n}.last
  last_sign_in = sign_in.present? ? sign_in.to_date : nil 
  
  p last_sign_in
  
  
  # p n.created_at
  # p n.reviewed_at
  # p (n.reviewed_at.present? ? n.reveiwed_at.to_date : n.created_at.to_date)

  out << [n.admin_user,name, (n.try(:reviewed_at).present? ? n.try(:reviewed_at) : n.try(:created_at)), n.email, n.fullname, n.phone, all_sign_count, last_sign_in, all_booking_count, all_booking_price]
end

Emailer.send_custom_file(['huyuzhuo@haihuilai.com', 'chenyilin@haihuilai.com'],  "2016年-2017年4月采购商流水数据统计", XlsGen.gen(out), "2016年-2017年4月采购商流水数据统计.xls" ).deliver_now
Emailer.send_custom_file(['wudi@haihuilai.com', ],  "2016年-2017年4月采购商流水数据统计", XlsGen.gen(out), "2016年-2017年4月采购商流水数据统计.xls" ).deliver_now



bds = Storage::Base::MG_AREA_BD
# 雪姐  奥乐 途风

out = [["采购商", "区域", "6月成交量", "6月成交金额", "7月成交量", "7月成交金额", "8月成交量", "8月成交金额"]]

span = ["2016-06-01", "2016-07-01", "2016-08-01"]
bds.each do |zone ,name|
 all_company = Consumer.where(:admin_user.in => name[:name], :review_status => "审核通过", :company_name.nin => [/TP/, /测试/]).map(&:company_name).uniq
 zone_key = zone
 p name[:name]
 p zone_key
 all_company.each do |n|
   month_data = [n, zone_key]
   span.each do |date|
     p n
     base_booking =  Booking.where(:consumer_company => n, :paid_at => date.to_date..date.to_date.next_month, :status.ne => "退单完成" )
     month_data.concat([base_booking.count, base_booking.map(&:total_rmb).reduce(:+).to_f.round(2)])
   end
   out << month_data

 end
end

Emailer.send_custom_file(['wudi@haihuilai.com', ],  "2016年6-8采购商数据统计", XlsGen.gen(out), "2016年6-8采购商流水数据统计.xls" ).deliver_now

out = [["采购商", "区域", "6月成交量", "6月成交金额", "7月成交量", "7月成交金额", "8月成交量", "8月成交金额"]]

span = ["2016-06-01", "2016-07-01", "2016-08-01"]

all_company = Consumer.where(:admin_user.in => ["金雪", "周伍骏"] , :review_status => "审核通过", :company_name.nin => [/测试/]).map(&:company_name).uniq;nil

all_company.each do |n|
  month_data = [n, ""]
  span.each do |date|
    p n
    base_booking =  Booking.where(:consumer_company => n, :paid_at => date.to_date..date.to_date.next_month, :status.ne => "退单完成" )
    month_data.concat([base_booking.count, base_booking.map(&:total_rmb).reduce(:+).to_f.round(2)])
   end
   out << month_data
end


### 画像统计 
#
out = [[]]
out = [["区域", "采购商所在城市（地址）", "城市", "采购商名称", "客户属性", "订单区域（前五城市）",  "历史交易量订单类型（包车）", "历史交易量订单类型（接送机）", "历史交易记录（订单数量）", "历史交易记录（订单交易金额）", "平均单价", "客户活跃度（分级ABC)"]]
bds = Storage::Base::MG_AREA_BD


bds.each do |zone ,name|
 all_company = Consumer.where(:admin_user.in => name[:name], :review_status => "审核通过", :company_name.nin => [/TP/, /测试/]).map(&:company_name).uniq
 all_company.each do |n|
     base_booking =  Booking.where(:consumer_company => n, :status.ne => "退单完成" )
     c = Consumer.where(:company_name => n, :manager_id => nil).first
     res = base_booking.map_reduce(
       %Q{
          function(){
            var city = this.from_city;
            var type = this.type;
            var price = this.total_rmb;
            emit({city: city, type: type}, {price: price, count: 1})
          }
       },
       %Q{
          function(key,items){
             var r = {price: 0, count: 0}
             items.forEach(function(item){
                r.price += item.price;
                r.count += item.count;
             })
             return r;
          }
          
       }
     ).out(:inline => true).to_a

     # 订单区域前五
     all_city = res.map{|x| x["_id"]["city"]}.uniq
     city_array = []
     all_city.each do |city|
       city_count = res.select{|m| m["_id"]["city"] == city}.map{|m| m["value"]["count"]}.reduce(:+).to_i
       city_array << [city, city_count]
     end
     city_sort = city_array.sort_by{|m| -m[1]}.slice(0,5)

     ## 包车交易订单量
     car_count = res.select{|m| m["_id"]["type"] =~ /包车/}.map{|m| m["value"]["count"]}.reduce(:+).to_i
     air_count = res.select{|m| m["_id"]["type"] =~ /机/ || m["_id"]["type"] =~ /站/}.map{|m| m["value"]["count"]}.reduce(:+).to_i
     all_count = res.map{|m| m["value"]["count"]}.reduce(:+).to_i
     all_price = res.map{|m| m["value"]["price"]}.reduce(:+).to_i

     address = c.try(:company_address)
     c_city = address.present? ? address[0..2] : nil
     ave = all_count !=0 ? (all_price / all_count).to_f : 0
     out << [zone, c.try(:company_address), c_city, n, "", city_sort, car_count, air_count, all_count, all_price, ave, ""]

 end
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "用户画像数据", XlsGen.gen(out), "用户画像统计数据.xls" ).deliver

Emailer.send_custom_file(['wudi@haihuilai.com'],  "各城市车导信息", XlsGen.gen(out, send), "各城市车导信息统计.xls" ).deliver



## 本月退单明细
#
out = [["订单号", "国家", "城市", "采购商", "OP", "责任BD", "金额", "支付时间", "订单更新时间", "订单类型"]]
Booking.where(:paid_at => Time.now.beginning_of_month..Time.now, :status => "退单完成").each do |n|
  out << [n.booking_param, n.from_country, n.from_city, n.consumer_name, n.op, n.sell_name, n.total_rmb, n.paid_at.to_date.to_s, n.updated_at, n.type]
end

Emailer.send_custom_file(['wudi@haihuilai.com'],  "6月支付后退单信息", XlsGen.gen(out), "6月支付后退单信息.xls" ).deliver_now



## 华东地区采购商历史登陆统计
c = Consumer.where(:admin_user => '张海英（华东）', :review_status => "审核通过", :manager_id => nil)

all_consumer = c.map(&:company_name).uniq

out = [["采购商", "登录次数", "开户时间", "最后一次登录时间", "交易金额", "交易目的地(金额)", "交易目的地(单量)"]]

all_consumer.each do |n|
  c = Consumer.where(:admin_user => '张海英（华东）', :review_status => "审核通过", :manager_id => nil, :company_name => n)
  base_booking =  Booking.where(:consumer_company => n, :status.ne => "退单完成" )
  res = base_booking.map_reduce(
    %Q{
          function(){
            var city = this.from_city;
            var type = this.type;
            var price = this.total_rmb;
            emit({city: city}, {price: price, count: 1})
          }
    },
      %Q{
          function(key,items){
             var r = {price: 0, count: 0}
             items.forEach(function(item){
                r.price += item.price;
                r.count += item.count;
             })
             return r;
          }

    }
  ).out(:inline => true).to_a

  # 订单区域前五
  all_city = res.map{|x| x["_id"]["city"]}.uniq
  city_array = []
  all_city.each do |city|
    city_count = res.select{|m| m["_id"]["city"] == city}.first["value"]["count"]
    city_array << [city, city_count]
  end
  city_price = []
  all_city.each do |city|
    city_p = res.select{|m| m["_id"]["city"] == city}.first["value"]["price"]
    city_price << [city, city_p]
  end

  all_price = base_booking.map(&:total_rmb).reduce(:+).to_f.round(2)
  all_sign_count = c.map(&:sign_in_count).compact.reduce(:+)
  sign_in = c.map{|n| n.try(:last_sign_in_at)}.compact.sort_by{|n| n}.last

  create_time = c.first.try(:reviewed_at).present? ? c.first.reviewed_at.to_date.to_s : c.first.try(:created_at).to_date.to_s

  out << [c.first.company_name, all_sign_count, create_time, sign_in, all_price,  city_price, city_array,]

end


out_e = [["采购商", "开户人", "登录次数", "开户时间", "最后一次登录时间", "交易金额", "交易目的地(金额)", "交易目的地(单量)"]]


c = Consumer.where(:admin_user => '张海英（华东）', :review_status => "审核通过", :manager_id => nil)

c.each do |n|
  id = n.id
  base_booking =  Booking.where(:consumer_id => id, :status.ne => "退单完成" )
  res = base_booking.map_reduce(
    %Q{
          function(){
            var city = this.from_city;
            var type = this.type;
            var price = this.total_rmb;
            emit({city: city}, {price: price, count: 1})
          }
    },
      %Q{
          function(key,items){
             var r = {price: 0, count: 0}
             items.forEach(function(item){
                r.price += item.price;
                r.count += item.count;
             })
             return r;
          }

    }
  ).out(:inline => true).to_a

  # 订单区域前五
  all_city = res.map{|x| x["_id"]["city"]}.uniq
  city_array = []
  all_city.each do |city|
    city_count = res.select{|m| m["_id"]["city"] == city}.first["value"]["count"]
    city_array << [city, city_count]
  end
  city_price = []
  all_city.each do |city|
    city_p = res.select{|m| m["_id"]["city"] == city}.first["value"]["price"]
    city_price << [city, city_p]
  end

  all_price = base_booking.map(&:total_rmb).reduce(:+).to_f.round(2)
  sign_in_count = n.sign_in_count
  last_sign_in_at = n.try(:last_sign_in_at)
  create_time = c.first.try(:reviewed_at).present? ? c.first.reviewed_at.to_date.to_s : c.first.try(:created_at).to_date.to_s
  out_e << [n.company_name, n.fullname, sign_in_count, create_time, last_sign_in_at, all_price, city_price,  city_array]

end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "华东采购商数据分析", XlsGen.gen(out,out_e), "华东采购商数据分析.xls" ).deliver




### 直客VIP  
#
#
out = [["订单号", "姓名", "电话"]]
Booking.where(:consumer_company => "直客VIP").each do |n|
  out << []
end



out =[["采购商", "BD", "类型", "订单量", "订单金额", "利润", "利润率"]]
Consumer.where(:company_name => /百程/,:review_status => "审核通过").each do |n|

  id = n.id
  p id

  order = Booking.where(:paid_at => Time.parse("2017-04-01")..Time.now,:consumer_id => id, :status.ne => "退单完成", :type.in => [/接/,/送/])

  price = order.map(&:total_rmb).reduce(:+)
  profit = order.map(&:company_profit).reduce(:+)
  out << [n.company_name, n.admin_user, order.count, price.to_f, profit.to_f,  Storage::Base.get_ratio(profit, price)]
  

end





# 汇总信息

# 详细信息

info_out = [["区域", "订单号", "订单类型", "大区", "国家", "城市", "采购价", "供应价", "毛利率", "优惠券"]]

bds = Storage::Base::MG_AREA_BD
bds.each do |zone ,name|

  bd = name[:name]

  all_booking = Booking.where(:paid_at => Time.parse("2017-07-01")..Time.parse("2017-08-01"), :sell_name.in => bd,:status.ne => "退单完成")

  
  all_booking.each do |n|
    supplier_name = n.supplier_name
    profit = n.company_profit
    info_out << [zone, n.booking_param, n.type, n.zone, n.from_country, n.from_city, n.total_rmb, n.supplier_total_rmb,"#{Storage::Base.get_ratio(profit, n.total_rmb)}%" , n.coupon_id.present?]
  end
end

info_out_reduce = [["区域", "采购价", "供应价", "毛利率", "成单量", "本月询价单量",  "本月询价成单量", "询价转化率", "新增账号量"]]
bds = Storage::Base::MG_AREA_BD
bds.each do |zone ,name|

  bd = name[:name]


  span = Time.parse("2017-07-01")..Time.parse("2017-08-01")

  all_booking = Booking.where(:paid_at => span, :sell_name.in => bd,:status.ne => "退单完成")


  all_price = all_booking.map(&:total_rmb).reduce(:+)
  #all_supplier = all_booking.where(:supplier_name.nin => /好巧/).map(&:total_rmb)
  all_supplier = all_booking.map(&:supplier_total_rmb).reduce(:+)
  all_profit = all_booking.map(&:company_profit).reduce(:+)


  all_count = all_booking.count

  all_consumer = Consumer.where(:review_status => "审核通过", :admin_user.in => bd,)
  m_all_consumer = all_consumer.where(:reviewed_at => span)
  m_consumer_count = m_all_consumer.count

  all_consumer_id = all_consumer.map(&:id)

  base_pt = PriceTicket.where(:consumer_id.in => all_consumer_id)
  month_pt = base_pt.where(:created_at => span)

  ratio_pt_month = ratio_pt_booking(span, month_pt, all_booking)

  info_out_reduce << [zone, all_price.round(2), all_supplier.round(2), "#{Storage::Base.get_ratio(all_profit, all_price)}%", all_count, month_pt.count, ratio_pt_month[0], "#{ratio_pt_month[1]}", m_consumer_count ]


end

def ratio_pt_booking(span, pt_info , booking_info)
  pt_ids = []
  all_booking = booking_info.where(:paid_at => span, :price_ticket_ids.ne => [])
  all_booking.each{|n| n.price_ticket_ids.each{|m| pt_ids<< m}}
  in_pt_count = pt_info.where( :id.in => pt_ids).count
  ratio = Storage::Base.get_ratio( in_pt_count, pt_info.count)
  return [in_pt_count, ratio]
end





Emailer.send_custom_file(['huyuzhuo:@haihuilai.com'],  "7月销售区域分类毛利汇总-kpi", XlsGen.gen( info_out, info_out_reduce), "7月销售区域毛利汇总.xls" ).deliver


ids = PriceTicket.where(:$where => "this.booking_params.length > 1").last.booking_params
ids.map{|n| n.to_i}

Booking.where(:paid_at.ne => nil, :booking_param.in => ids).count

out = [["订单号", "采购商",  "区域", "国家", "起始城市", "订单类型", "成交金额", "订单状态" ]]
Booking.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-07-01"), :sell_name => "卢钢", :status.ne => "退单完成").each do |n|
  out << [
  
    n.booking_param,
    n.consumer_company,
    n.zone,
    n.from_country,
    n.from_city,
    n.type,
    n.total_rmb,
    n.status,
  ]

end
Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "西南2017上半年销售统计", XlsGen.gen(out), "西南2017上半年销售统计.xls" ).deliver



## 采购商成交前30合同补签

res = Booking.collection.aggregate([
  {
    :$match => {
      #:created_at => {:$gte =>(Time.parse("18:00", d) - 7.days), :$lte => Time.parse("18:00", d)},
      :paid_at => {:$ne => nil},
      #:status => {:$nin => ['退单完成', '订单关闭']},
      :status => {:$nin => ['退单完成', '订单关闭']},
    }
  },
  {
    :$group => {
      #:consumer => '$consumer_name',
      :_id=> '$consumer_company',
      :price => {'$sum' => '$total_rmb'}
    }
  }
])

out = [["采购商", "历史成交"]]

res.each do |n|

  out << [n["_id"], n["price"].round(2)]
end



Emailer.send_custom_file(['huyuzhuo@haihuilai.com'],  "近一周退单信息", XlsGen.gen(out), "近一周退单信息.xls" ).deliver



out = [["单号", "订单类型", "国家","支付日期", "金额"]]
Booking.where(:paid_at => Time.parse("2016-01-01")..Time.now,:from_country.in => ["西班牙", "葡萄牙"], :status.ne => "退单完成").each do |n|
  out << [n.booking_param, n.type , n.from_country, n.consumer_company, n.total_rmb]
end

Emailer.send_custom_file(['jingxue@haihuilai.com', 'huyuzhuo@haihuilai.com'],  "更新-西班牙葡萄牙历史成交订单信息", XlsGen.gen(out), "西班牙葡萄牙历史成交订单信息.xls" ).deliver




out = [["订单号", "结算方式", "订单类型", "下单时间", "支付时间", "开始日期", '结算日期', "开始城市", "大区", "采购商公司", "BD", "金额", "人数", "导游级别", "车辆级别", "退单原因"]]
Booking.where(:updated_at => 8.day.ago..Time.now,:status => "退单完成").each do |n|
  out << [n.booking_param, n.payment_type, n.type, n.created_at.to_date, n.paid_at, n.from_date.to_date, n.to_date.to_date, n.from_city, n.zone, n.consumer_company, n.sell_name, n.total_rmb, n.people_num, n.driver_category, n.car_category, n.cancel_memo]
end


Consumer.where(:review_status => "审核通过")


out = [["id", "公司名称", "审核通过时间", "账号类型", "BD", "email", "登陆次数", "最后登陆时间"]]

Consumer.where(:review_status => "审核通过",:admin_user => /代理/).each do |n|
  out << [n.id, n.company_name, n.type, n.admin_user, n.email, n.last_sign_in_at, n.sign_in_count]
end
Emailer.send_custom_file([ 'huyuzhuo@haihuilai.com'],  "代理采购商信息", XlsGen.gen(out), "代理采购商信息.xls" ).deliver




# 更新订单中采购商名称
#
#
Booking.all.each do |n|

  id = n.consumer_id
  name = n.consumer_company

  consumer = n.consumer

  if consumer.company_name != name
    p n.booking_param
    p n.created_at.to_date.to_s
    p name
    p consumer.company_name
    p "+++++"
  end




end
# Top20 采购商信息
base_booking = Booking.real_order.where(:paid_at => Time.parse("2017-01-01")..Time.now, :status.ne => "退单完成")
res = base_booking.map_reduce(
  %Q{
          function(){
            var city = this.consumer_company;
            var price = this.total_rmb;
            emit({consumer: city, bd: this.sell_name}, {price: price, count: 1})
          }
  },
    %Q{
          function(key,items){
             var r = {price: 0, count: 0}
             items.forEach(function(item){
                r.price += item.price;
                r.count += item.count;
             })
             return r;
          }

  }
).out(:inline => true).to_a


a = res.sort_by{|n| -n["value"]["price"]}[0,30]

out = [["采购商", "BD", "总流水", "单量"]]
a.each do |n|
  out << [n["_id"]["consumer"], n["_id"]["bd"], n["value"]["price"] , n["value"]["count"]]
end


Emailer.send_custom_file(['huyuzhuo@haihuilai.com', "tongchang@haihuilai.com"],  "17年top30采购商", XlsGen.gen(booking_send), "本月新开账号订单统计数据.xls" ).deliver
