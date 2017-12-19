all = Booking.where(:memo.ne => nil).where(:memo.ne => "" , :consumer_name.not => /测试/)

st = ['订单已支付', '订单确认', '即将开始', '服务开始', '服务结束', '订单完成']
order = all.where(:status.in => st) 

type = ["接送机", nil]

airbooking = all.where(:status.in => st).where(:type => "接送机")
booking = all.where(:status.in => st).where(:type => "")

airbooking.count
a_m_r = airbooking.where(:memo.nin => ["",nil]).count



booking.count
d_r = booking.where(:travel_items_detail.nin => ["", [], nil] ).count
m_r = booking.where(:memo.nin => ["", nil] ).count
all_r = booking.where(:travel_items_detail.nin => ["", [], nil] ).where(:memo.nin => ["", nil] ).count

send = [ ['类型', '订单详情', '客人留言', '同时填写','总量']]

send << ["标准用车", d_r, m_r, all_r, booking.count]
send << ["接送机", nil, a_m_r, nil ,airbooking.count]

