

# 执行时间在未来4个月需要执行的订单
#
# 订单执行日期 include 



Booking.where(:paid_at.ne => nil, :from_date.gte => "2017-02-01".to_date, :to_date.lte => "")

date_out = {}
zone_all = Location.where(:category => "zone").map(&:name_cn)
zone_all.shift
start_day = Time.now
(1..6).each do |n|

  span_month_start = start_day.beginning_of_month + n.month
  span_month_end = span_month_start.end_of_month

  base = Booking.where(:paid_at.ne => nil, :from_date.gte => span_month_start, :to_date.lte => span_month_end, :status.nin =>  ['退单完成', '预订单失效', '订单未支付'], :op.not => /测试/)

  res = base.collection.aggregate([
    {
      :$match => {
        :paid_at => {:$ne => nil},
        :status => {:$nin => ['退单完成', '预订单失效', '订单未支付']},
        :consumer_company => {:$not => /测试/},
        :from_date => {:$gte => span_month_start},
        :to_date => {:$lt => span_month_end}
      }
    },
    {
      :$group => {
        :_id => "$zone",
        :count => {"$sum" => 1}
      }
    }
  
  ])


  zone_all.each do |zone|
      date_out[zone] ||= []
      rr = res.select{|x| x['_id'] == zone}.first
      date_out[zone] << (rr.present? ? rr["count"] : 0)
  end

  res.each do |x|
    p x
  end
  #date_out << count
end

Time.now.beginning_of_month..(Time.now+6.month).end_of_month.map{|n| "{n.to_s[0,4]}"}.uniq:wq
:

