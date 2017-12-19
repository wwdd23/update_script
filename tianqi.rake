out = [["ID", "姓名", "级别", "区域", "国家", "车队ID", "车队", "服务区域", "状态" ]]


Supplier.all.each do |n|
  out << [n.id, n.fullname, n.type_cn, n.zone, n.country_name, n.team_id, n.team_name, n.services_locations, n.review_status_cn]
end


Emailer.send_custom_file(['wudi@haihuilai.com'],  "车导信息列表详情", XlsGen.gen(out), "车导信息列表详情.xls" ).deliver
