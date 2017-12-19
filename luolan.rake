
span =
Booking.where(:paid_at => Time.parse("2017-01-01")..Time.parse("2017-11-01"),:sell_name => "张海英",:status.ne => "退单完成").



out = [["月份", "流水金额"]]
(1..11).each do |n|

  start_day = Time.parse("2017-#{n}-01")  
  end_day = Time.parse("2017-#{n}-01").end_of_month
 
  span = start_day..end_day
  all = Booking.where(:paid_at => span,:sell_name => "张海英",:status.ne => "退单完成").map(&:total_rmb).reduce(:+).round(2)
  out << [n, all]


end
