
%x{grep "2017-03-15" log/production.log | grep "SmsService" | awk -F ':' '{print $5 }' }



# 提取SmsService 字段内容
%x{grep "2017-03-15" log/production.log | grep "SmsService"| awk -F ' : ' '{print $2}'}
# "SmsService send_sms text:【还会来】系统监控: 正常!2017-03-15 09:20:11 +0800 to:13716271025 res: 测试环境\n"
#
%x{grep "2017-03-15" log/production.log | grep -o  "send_sms"}




def sms_log 

  date = "2017-03-15"
  info = %x{grep "2017-03-15" log/production.log | grep "SmsService"| awk -F ' : ' '{print $2}'}


  send = []
  info.each_line do |n|
    text = n.match(/text:(.*)to:/)[1]
    to = n.match(/to:(.*)res:/)[1].strip
    res = n.match(/res:(.*)/)[1]
    send << {:date => date, :text => text, to: to, :res => JSON.parse(res.gsub('=>', ':'))}
    # 将字符串转为hash
    #JSON.parse(b.gsub('=>' , ':'))
  end

end


info = %x{grep "2017-03-15" log/production.log | grep "SmsService"| awk -F ' : ' '{print $2}'}





info = %x{grep "2017-09-18" /opt/qwb_pro_log/production.log |grep '"form_class"=>"many_days_form"' }

type = {
  "many_days_form" => "多日包车",
  "one_day_form" => "一日包车",
  "arrive_form" => "接机站",
  "leave_form" => "接机站",
}

info.lines.count

type.each do |x,y|
  key = x
  v = y




end

info = %x{grep '"form_class"=>' /opt/qwb_pro_log/production.log* }

a = info.each_line.first
info.each_line do |n|
  time_string = n.match(/\[(.*) #.*\]/)[1]
  time = Time.parse(time_string)

  user_id = n.match(/\] \[(.*)\].*Parameters/)

  user_id_info = user_id[1]
  if user_id_info.include?("user_id")
    id = user_id_info.split(":")[1].to_i
  else
    id = nil
  end
  res = n.match(/Parameters:(.*)/)[1]
  r = JSON.parse(res.gsub("=>", ':'))

end


# placeauto

info = %x{grep "place_autocomplete:" /opt/qwb_pro_log/production.log* }

a = info.each_line.first

out = []
info.each_line do |n|


  time_string = n.match(/\[(.*) #.*\]/)[1]
  time = Time.parse(time_string)
  user_id = n.match(/\] \[(.*)\] place_autocomplete/)

  user_id_info = user_id[1]
  if user_id_info.include?("user_id")
    id = user_id_info.split(":")[1].to_i
  else
    id = nil
  end
  res = n.match(/place_autocomplete:(.*)/)[1]
  r = JSON.parse(res.gsub(':','"').gsub("=>", '":'))
  out << {:created_at => time, :user_id => id, :res => r}



end


