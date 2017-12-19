out = [["工单号", "订单类型", "开始时间", "开始城市", "采购商", "询价时间", "创建人", "关联订单", "留言", "指派原因", "状态", "车型", "人数", "导游"]]
PriceTicket.all.each do |n|

  out << [
    n.id, n.booking_type, n.from_date, n.try(:from_location).try(:name_cn),  n.consumer_name, n.created_at.to_date, n.try(:operator).try(:fullname),
    n.booking_params, n.memo, n.operator_reason, n.status, n.car_model, n.people_num, n.driver_category
  ]

end

Emailer.send_custom_file(['xusiyuan@haihuilai.com'],  "工单状态统计", XlsGen.gen(out), "工单状态统计.xls" ).deliver




 info = CSV.read(ENV['file_path'] || 'data/b.csv')
 
 out = [["城市", "车型", "车导", "城内价格", "城外价格"]]
 start_date = "2017-11-15"
 type = "one_day_form"
 info.each do |n|

	 filter = {
		 :form_class=> type,
		 # 不需要 category 内容 获取返回结果
		 # :car_category_name=>"5座舒适",
		 #:airport_code => airportcode,
		 :date => start_date,
     :city => n,
     #:city => "法兰克福"

		 #:date => "2016-11-19",
		 #:addr =>"日本〒259-1138 Kanagawa Prefecture, Isehara, Godo, ４１７−１"
		 #:addr => address,
	 }

	 hhl_data =  Storage::Fetcher.booking_price_diff(filter)
	 if hhl_data['data'].present?
		 hhl_data["data"].each do |m|
			 out << [n, m["car_category_name"], m["driver_category_name"], m["inside_city_price"], m["outside_city_price"]]
		 end
	 end

 end



 Emailer.send_custom_file(['wudi@haihuilai.com'],  "100+城市一日包车采购价信息", XlsGen.gen(out), "100+城市一日包车采购价信息.xls" ).deliver_now
