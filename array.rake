a = []
booking_ids.each do |n|

  a.concat(n)
end


b = Booking.where(:paid_at.ne => nil,:status.ne =>"退单完成").map(&:booking_param);nil

b - a 
