Booking.where(:created_at => Time.parse('2016-10-01')..Time.now).first.travel_items.map(&:detail) 

1. 判断是否有用户留言

2. 判断是否有行程留言



# 更新字段属性
#
Booking.all.each do |n|




end



(1..12).each do |n|
  start_day = "2016-#{n}-1".to_date
  end_day = start_day.next_month
  p end_day
  Booking.sync({:start_day => start_day,:end_day => end_day})
  #PriceTicket.sync({:start_day => start_day,:end_day => end_day})
end


Booking.all.map do |n|
  p n.zone.present? ? n.zone : ""
end.uniq

Booking.all.each do |n|
  if n.try(:location).present?
    
    name = n.location
    n.update(:zone => n.location)
  end
end



Consumer.all.each do |n|
  curr_at = n.current_sign_in_at
  if curr_at.present?
    n.update(:current_sign_in_at => curr_at.to_time)
  end
end


#通过每日数据刷新 订单数据
span = "2015-10-01".to_date..Time.now.to_date
span = "2017-02-01".to_date.."2017-02-08".to_date
span = "2017-02-08".to_date..Time.now.to_date
span.each do |n|
  p n.to_s
  filter = {:date => n.to_s}
  data = Storage::Fetcher.bookings(filter)
  if data['status'] == 200
    data['result'].each do |n|
      d = Booking.where(:id => n['id']).first
      d ? d.update(n) : Booking.create!(n)
    end
  end
end


# 未来15天执行订单量
# 未来15执行订单 每个订单的日期区间， 统计后统计每个日期出现的频率

bookings = Booking.where(:paid_at.ne => nil, :status.nin => ['退单完成', '预订单失效', '订单未支付'], :consumer_company.not => /测试/)

dates = bookings.where(:from_date.gte => Time.now.to_date, :to_date.lte => (Time.now.to_date + 16.day)).map do |n|
 (n.from_date..n.to_date).map{|n| n.to_s}
end.flatten

def a_count
  k=Hash.new(0)
  self.each{|x| k[x]+=1}
  k
end

res = dates.a_count

all_date = res.map{|k,v| k}

# 15日各地区区间
search_date = Time.now.to_date.to_s
a = Booking.collection.aggregate([
  {
    :$match => {
      :paid_at => {:$ne => nil},
      :status => {:$nin => ['退单完成', '预订单失效', '订单未支付']},
      :consumer_company => {:$not => /测试/},
      :from_date => {:$gte => Time.parse(search_date)},
      :to_date => {:$lt => (Time.parse(search_date) + 16.day)}
    }
  },
  {
    :$group => {
      :_id => "$zone",
      :time => {"$push" => {:start_day => {"$substr" => ["$from_date",0,10]}, :end_day => {"$substr" => ["$to_date",0,10]}}}
    }
  }
])

send_out = {}
a.each do |n|
  #send_out["#{n["_id"]}"] ||= []
  all_date = n['time'].map{|m| (m["start_day"].to_date..m["end_day"].to_date).map{|x| x.to_s}}.flatten
  send_out["#{n["_id"]}"] = hash_count(all_date)
end

doing_span = Time.now.to_date..(Time.now + 15.day).to_date
date_info_zone =  {}

send_out.keys.each do |zone|
  doing_span.map{|row| row.to_s}.each do |day|
    #r = dates.select{|k,v| k = day}
    date_info_zone[zone] ||= []
    date_info_zone[zone] << send_out[zone][day].to_i
  end
end


# 前12月日期区间计算
# 生成数组

span = 12.month.ago.beginning_of_month.to_date..Time.now._of_month.to_date
step = span.map{|n| n.strftime("%Y-%m") }.uniq



Booking.where(:leave_item_addr.ne => nil, :arrive_item_addr.ne => nil)
arrive = Booking.where( :arrive_item_km.ne => nil, :comsuer_company.nin => [/TP/])
out = [["国家", "城市", "机场", "机场三字码", "地址", "公里", "出现次数"]]
send = []
arrive.each do |n|
  
  send << [n.to_country, n.to_city, n.pickup_airport["name_cn"], n.pickup_airport["code"], n.arrive_item_addr, n.arrive_item_km]
end

leave = Booking.where( :leave_item_km.ne => nil, :comsuer_company.nin => [/TP/])
leave.each do |n|
  
  send << [n.to_country, n.to_city, n.drop_off_airport["name_cn"], n.drop_off_airport["code"], n.leave_item_addr, n.leave_item_km]
end

# 计算数组重复字符数量
def a_count
  k=Hash.new(0)
  self.each{|x| k[x]+=1}
  k
end

x = send.a_count


a = []
x.each do |n,m|
#  a<<[n,m]
  nn = n.clone
 a <<  nn.push(m)
end

out.concat(a)

Emailer.send_custom_file(['diaoxue@haihuilai.com', 'chenyilin@haihuilai.com'],  "[运营数据分析]历史接送机目的地信息数据", XlsGen.gen(a), "历史接送机目的地信息数据.xls" ).deliver

