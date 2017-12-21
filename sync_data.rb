(1..29).each do |n|
  start_day = "2017-10-#{n}".to_date
  end_day = start_day.next_day
  p n
  Booking.sync({:start_day => start_day,:end_day => end_day, :sync_type => "created_at"})
  #PriceTicket.sync({:start_day => start_day,:end_day => end_day})
  #Consumer.sync({:start_day => start_day,:end_day => end_day})
  #PayLog.sync({:start_day => start_day,:end_day => end_day})
  #Transaction.sync({:start_day => start_day,:end_day => end_day})
end



(Time.parse("2017-11-01").to_date..Time.now.to_date).each do |n|
  start_day = n
  end_day = n.next_day
  p n
  Booking.sync({:start_day => start_day,:end_day => end_day, :sync_type => "created_at"})

end


(10.day.ago.to_date..1.day.ago.to_date).each do |n| 
  date = n.to_s

  SmsLog.sync({:date => date})

end


(Time.parse("2017-03-14").to_date..Time.parse("2017-03-16").to_date).each do |n|

  date = n.to_s

  SmsLog.sync({:date => date})

end


(Time.parse("2015-10-01").to_date..Time.now.to_date).each do |n|

  start_day = n.to_s
  end_day = n.next_day.to_s
  #Supplier.sync({:start_day => start_day,:end_day => end_day})
  #Consumer.sync({:start_day => start_day,:end_day => end_day, :sync_type => "created_at"})
  Booking.sync({:start_day => start_day,:end_day => end_day, :sync_type => "created_at"})
  #Traveller.sync({:start_day => start_day,:end_day => end_day})
end 

(Time.parse("2017-11-28").to_date..Time.now.to_date).each do |n|

  start_day = n.to_s
  InsureLog.synclog(start_day)
end 
