a = Booking.where(:paid_at => Time.parse("2017-09-01")..Time.parse("2017-10-01"), :status.ne => "退单完成")

types = a.map(&:type)


types.map do |n|
  [n, a.where(:type => n).count, a.where(:type =>n).map(&:total_rmb).reduce(:+)]
end



span = Time.parse("2")
