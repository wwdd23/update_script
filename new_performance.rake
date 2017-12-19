tp_list = [/浙江三博会展/, /TP/, /测试/, /上海你行我行网络科技/, "北京高泰国际旅行社有限公司", /旅行顾问/, /体博/, /中金环球国际/, /德铁/]


sell_name = 

name = Storage::Base::MG_AREA_BD


info = []
name.each do |x,y|
  info.concat(y[:name])
end

Booking.where(:paid_at => Time.parse("2017-10-01")..Time.parse("2017-12-01"), :consumer_company.nin => tp_list, :sell_name.nin => info, :status.ne => /退/)




