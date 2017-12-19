info = CSV.read(ENV['file_path'] || 'data/searchlocation.csv')

info = CSV.read('data/20170417_ctrip_air.csv')
all_url = []
time_list = [ "2017-5-6",  "2017-6-14",  "2017-4-14", "2017-04-29", ]

time_span = (Time.now.tomorrow.to_date..Time.parse("2017-06-15")).map{|n| n.to_s}



time_span.each do |date|
	info.each do |res|

		(17..18).each do |type|
			base_url = "http://car.ctrip.com/hwdaijia/list?ptType=#{type}&cid=#{res[0]}&useDt=#{date}%2009:00&flNo=&dptDt=0001-01-01%2000:00&locNm=&locCd=#{res[1]}&locType=1&locSubCd=&locSubType=0&poiCd=&poiType=2&poiNm=#{res[2]}&poiAddr=&poiLng=#{res[3]}&poiLat=#{res[4]}&poiref=&addrsource=se&chtype=2"
			Task.transaction do
				task_info = {
					url: base_url,
					project:'ctrip_qwb',
					category: 'normal',
					script_name: 'ctrip_qwb/air_ctrip_casper.js',
					context: '',
				}
				Task.create!(task_info)
			end
		end
	end
end


info = CSV.read("/tmp/logo_consumer.csv")


send = [["ID", "采购商", "注册人", "BD", "联系方式", "账号类型", "审核状态", "是否上传logo"]]
info.each do |n|

  st = n[3]
  id = n[0].to_i
  c = Consumer.where(:id => id).first
  type = c.manager_id.nil? ? "主账号": "子账号"


  send << [c.id, c.company_name, c.fullname, c.admin_user, c.phone, type, c.review_status, st]

end

Emailer.send_custom_file(['wudi@haihuilai.com'], "采购商上传logo状态统计", XlsGen.gen(send), "采购商上传logo状态统计.xls").deliver_now
