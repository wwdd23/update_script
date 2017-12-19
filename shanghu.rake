def report_bsc_mail (span) ## 商户服务中心 bsc busniess service center
  @day = Time.now.to_date.to_s
  case span
  when "day"
    date_span = 1.day.ago.to_date..@day.to_date

    @title = "#{1.day.ago.to_date.to_s} 商户服务中心日报"
    @mail_info = "#{1.day.ago.to_date.to_s}）商户中心日报"

    view_data




  when "week"
    date_span = @day.to_date.beginning_of_week.prev_week..@day.to_date
    @title = "商户中心周报#{date_span.first.to_s}-#{date_span.last.to_s} "
    mail_info = "商户中心周报#{date_span.first.to_s}-#{date_span.last.to_s} "

  when "month"
    date_span = @day.to_date.beginning_of_month.prev_month..@day.to_date.beginning_of_month
    @title = "商户中心月报#{date_span.first.strftime("%Y/%m")}-#{date_span.last.strftime("%Y/%m")} "
    mail_info = "商户中心月报#{date_span.first.strftime("%Y/%m")}-#{date_span.last.strftime("%Y/%m")} "

  end

  attachments["#{@title}.xls"] = {
    mime_type: "application/octet-stream",
    content: XlsGen.gen(@consumer_send , @booking_send, @price_ticket_send, @sells_send)
  }
  mail(:to => emails,:cc => (emails == []),:subject => @title)

end




private

dspan =  1.day.ago.to_date..Time.now.to_date



def view_data(dspan)
  book_base = Booking.where(:paid_at => dspan,)

  res = Booking.collection.aggregate([
    {
      :$match => {
        :paid_at => {:$gte => dspan.first, :$lt => dspan.last,},
        :op => {:$nin => [/测试/]}
      }
    },
    {
      :$group => {
        :_id => {:type => '$type', :city_id => '$from_location_id'},
        :sub_price => {'$sum' => '$total_rmb'},
        :count => {'$sum' => 1},
      }
    }
  ])

  airbook = res.select{|n| n["_id"]["type"] == "接送机"}
  count_air = airbook.map{|n| n["count"]}.reduce(:+) # 接送机单数
  #airbook.sort{|x,y| y["count"] <=> x["count"]} #排序 降序 去前三 
  air_sort = airbook.sort_by{|n| -n["count"]}.take(3)

  air_send = [["类型", "城市", "订单量", "成交金额"]]
  air_sort.each do |n|
    type = n["_id"]["type"]
    city = Location.where(:id => n["_id"]["city_id"]).first.try(:name_cn)
    price = n["sub_price"]
    count = n["count"]
    air_send<<[type, city, count, price]
  end
  book = res.select{|n| n["_id"]["type"] == ""}
  count_book = book.map{|n| n["count"]}.reduce(:+) # 标准用车单数
  book_sort = book.sort_by{|n| -n["count"]}.take(3)
  book_send = [["类型", "城市", "订单量", "成交金额"]]
  book_sort.each do |n|
    type = n["_id"]["type"]
    city = Location.where(:id => n["_id"]["city_id"]).first.try(:name_cn)
    price = n["sub_price"]
    count = n["count"]
    book_send<<[type, city, count, price]
  end

  # 成交金额
  paid_price = res.map{|n| n["sub_price"]}.reduce(:+)

  # 今日询价
  base_price = PriceTicket.where(:created_at => dspan)

  p_res = PriceTicket.collection.aggregate([
    {
      :$match => {
        :created_at => {:$gte => dspan.first, :$lt => dspan.last,},
        :consumer_name => {:$nin => [/测试/]}
      }
    },
    {
      :$group => {
        :_id => '$city',
        :count => {'$sum' => 1},
      }
    }
  ])
  # 排序
  price_sort  = p_res.sort_by{|n| -n["count"]}.take(3) # 前三询价订单城市

  city_price = [['城市', '数量']]
  price_sort.each{|n| city_price << [n["_id"], n["count"]]}

  all_count = base_price.count
  will_price_count = base_price.where(:status => "待报价").count
  paid_price_count =base_price.where(:status => "已付款").count

  out = {}
  
  out = {
   :all_count => all_count, #成单数
   :air_count => count_air, #接送机单数
   :book_count => count_book,  #标准用车单数
   :air_data => air_send, #接送机前三数据
   :book_data => book_send, #标准用车前三数据
   :paid_price => paid_price, #成交金额
   :count_price => base_price.count, #询价单数量
   :priceticket_data => city_price, #询价单前三数据
   :will_count => will_price_count, #未报价订单数量
   :paid_count => paid_price_count, #已付款询价单数量
  }
end

def xls_data(date)
  # excel表格数据
  #

  ###  工单数据
  xls_price = [["工单号","采购商公司","城市","区域","询价日期","行程开始日期","创建人","报价金额","工单状态","未报价原因","单号"]]

  base_price.each do |n|
    xls_price << [
      n.id,
      n.consumer_name,
      n.try(:city),
      n.from_location.parent.parent.try(:name_cn), #zone
      n.created_at.to_date,
      n.from_date.to_date,
      n.creater.try(:fullname),
      n.price,
      n.status,
      "",
      n.booking_params,
    ]
  end

  #### 订单数据 
  xls_booking = [["是否标品","订单号","订单状态","导游级别","订单类型","下单时间","开始日期","城市","大区","采购商公司","下单人","供应商", "供应商公司", "驾驶员","金额 利润","意见单","投诉"]]

  book_base.each do |n|
    xls_booking << [
      "",
      n.booking_param,
      n.status,
      n.driver_category,
      n["type"].present? ? n["type"] : "标准用车",
      n.created_at.to_date,
      n.from_date.to_date,
      n.from_location.try(:name_cn),
      n.from_location.parent.parent.try(:name_cn),
      n.consumer_company,
      n.creater_name,
      n.supplier_name,
      n.supplier.try(:company_name),
      n.try(:driver_name),
      n.total_rmb,
      n.company_profit,
      n.is_opinions,
      n.is_complaint,
    ]
  end


end

daily_send = [[]]


dspan = 1.day.ago.to_date..Time.now.to_date
#今日成单
book_base = Booking.where(:paid_at => dspan,)
# 今日成单
book_count = book_base.count
# 接送机
air_count = airbook.count
#标准用车
book_count = book.count

res = Booking.collection.aggregate([
  {
    :$match => {
      :paid_at => {:$gte => dspan.first, :$lt => dspan.last,},
      :op => {:$nin => [/测试/]}
    }
  },
  {
    :$group => {
      :_id => {:type => '$type', :city_id => '$from_location_id'},
      :sub_price => {'$sum' => '$total_rmb'},
      :count => {'$sum' => 1},
    }
  }
])

airbook = res.select{|n| n["_id"]["type"] == "接送机"}
count_air = airbook.map{|n| n["count"]}.reduce(:+) # 接送机单数
#airbook.sort{|x,y| y["count"] <=> x["count"]} #排序 降序 去前三 
air_sort = airbook.sort_by{|n| -n["count"]}.take(3)

air_send = [["类型", "城市", "订单量", "成交金额"]]
air_sort.each do |n|
  type = n["_id"]["type"]
  city = Location.where(:id => n["_id"]["city_id"]).first.try(:name_cn)
  price = n["sub_price"]
  count = n["count"]
  air_send<<[type, city, count, price]
end

book = res.select{|n| n["_id"]["type"] == ""}
count_book = book.map{|n| n["count"]}.reduce(:+) # 标准用车单数
book_sort = book.sort_by{|n| -n["count"]}.take(3)
book_send = [["类型", "城市", "订单量", "成交金额"]]
book_sort.each do |n|
  type = n["_id"]["type"]
  city = Location.where(:id => n["_id"]["city_id"]).first.try(:name_cn)
  price = n["sub_price"]
  count = n["count"]
  book_send<<[type, city, count, price]
end

# 成交金额
res.map{|n| n["sub_price"]}.reduce(:+)
# 今日询价
base_price = PriceTicket.where(:created_at => dspan)

p_res = PriceTicket.collection.aggregate([
  {
    :$match => {
      :created_at => {:$gte => dspan.first, :$lt => dspan.last,},
      :consumer_name => {:$nin => [/测试/]}
    }
  },
  {
    :$group => {
      :_id => '$city',
      :count => {'$sum' => 1},
    }
  }
])
# 排序
price_sort  = p_res.sort_by{|n| -n["count"]}.take(3) # 前三询价订单城市
all_count = base_price.count
will_price_count = base_price.where(:status => "待报价").count
paid_price_count =base_price.where(:status => "已付款").count

# excel表格数据
#

###  工单数据
xls_price = [["工单号","采购商公司","城市","区域","询价日期","行程开始日期","创建人","报价金额","工单状态","未报价原因","单号"]]

base_price.each do |n|
  xls_price << [
    n.id,
    n.consumer_name,
    n.try(:city),
    n.from_location.parent,parent.try(:name_cn), #zone
    n.created_at.to_date,
    n.from_date.to_date,
    n.creater.try(:fullname),
    n.price,
    n.status,
    "",
    n.booking_params,
  ]
end

#### 订单数据 
xls_booking = [["是否标品","订单号","订单状态","导游级别","订单类型","下单时间","开始日期","城市","大区","采购商公司","下单人","供应商", "供应商公司", "驾驶员","金额 利润","意见单","投诉"]]

base_book.each do |n|
  xls_booking << [
    "",
    n.booking_params,
    n.status,
    n.driver_category,
    n["type"].present? ? n["type"] : "标准用车",
    n.created_at.to_date,
    n.from_date.to_date,
    n.from_location.try(:name_cn),
    n.from_location.parent.parent.try(:name_cn),
    n.consumer_company,
    n.creater_name,
    n.supplier_name,
    n.supplier.try(:company_name),
    n.driver_name,
    n.total_rmb,
    n.company_profit,
    n.is_opinions,
    n.is_complaint,
  ]
end
