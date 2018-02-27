# 王宇11月操作订单
ids = [2036218240, 2034266643, 2033427618, 400264986, 358678737, 357792096, 321442481, 566390712, 775161959, 914744122, 900427502, 887916307, 1271235397, 1270347220, 1268330087, 1460848352, 1455739773, 1491624618, 1735695763, 1676194530, 1674370556]

s = Booking.where(:booking_param.in => ids).map(&:company_profit).reduce(:+)
t = Booking.where(:booking_param.in => ids).map(&:total_rmb).reduce(:+)



# 获取符合操作订单
#
all_booking = Booking.where(:paid_at.gte => Time.parse("2017-12-01"), :to_date => span, :status => "订单完成" )

booking_ids = all_booking.map("")
