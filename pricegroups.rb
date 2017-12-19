AirportPriceGroup.where(' to_date >= ?', Time.now.to_date)
 AirportPriceGroup.includes(:airport).where(' to_date >= ?', Time.now.to_date).map{|n| [n.airport_id, n.airport.name_cn]}


air_location =AirportPriceGroup.includes(:airport).where(' to_date >= ?', Time.now.to_date).map{|n| 
  {n.airport.location.id => n.airport.location.name_cn}
}.uniq



car_location = PriceGroup.where(' to_date >= ?', Time.now.to_date).map{|n| 
  {n.location.id => n.location.name_cn}
}.uniq


a = (air_location + car_location).uniq

data = {}
a.each do |n|

  data.merge!(n)

end



