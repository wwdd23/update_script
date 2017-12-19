city_ids = Booking.where(:paid_at.ne => nil, :status.ne => "退单完成").map_reduce(
    %Q{
          function(){
            var city = this.from_city;
            emit({city: city}, { count: 1})
          }
    },
      %Q{
          function(key,items){
             var r = {count: 0}
             items.forEach(function(item){
                r.count += item.count;
             })
             return r;
          }

    }
  ).out(:inline => true).to_a
 


city_ids.map{ |n|  [n["_id"]["city"], n["value"]["count"]]}.sort_by{|m|  -m[1]}[0,30]



# 去年12月下单采购商信息
# 除去走账流水账户
#
span = Time.parse("2016-11-01")..Time.parse("2017-01-01")

span1 = Time.parse("2017-11-01")..Time.parse("2018-01-01")

base_booking_old = Booking.real_order.where(:paid_at => span,:status.ne => "退单完成")

base_booking_new = Booking.real_order.where(:paid_at => span1,:status.ne => "退单完成")



consumers_o = base_booking_old.map(&:consumer_company).uniq;nil
consumers_n = base_booking_new.map(&:consumer_company).uniq;nil


all_c = (consumers_o + consumers_n).uniq

out = [["采购商", "BD", "201611~12月下单量", "16-12月出行量", "17-1月出行量", "17-2月出行量", "17-3月出行量", "17-4月出行量", "201711~12月下单量", "17-12月出行量", "18-1月出行量", "18-2月出行量", "18-3月出行量", "18-4月出行量"]]

all_c.each do |n|

  ds_old = base_booking_old.where(:consumer_company => n).map{|m| m.from_date.strftime("%Y%m")}
  ds_new = base_booking_new.where(:consumer_company => n).map{|m| m.from_date.strftime("%Y%m")}
  cal_old = Storage::Base.hash_count(ds_old)
  cal_new = Storage::Base.hash_count(ds_new)

  p cal_new
  c = Consumer.where(:company_name => n,:manager_id => nil).first
  sell_name = c.admin_user
  
  find_span_old = (span.first.to_time.to_date..(span.first + 4.month).to_time.to_date).map{|n| n.strftime("%Y%m")}.uniq
  find_span_new = (span1.first.to_time.to_date..(span1.first + 4.month).to_time.to_date).map{|n| n.strftime("%Y%m")}.uniq

  tmp = [n, sell_name, ds_old.count, ]
 
  find_span_old.each do |step|
    b =  cal_old.select{|k,v|k == step}
    p b 
    if b.present? 
      tmp << b.values().first
    else
      tmp << 0
    end
  end
  tmp_new = [ds_new.count]
  find_span_new.each do |step|
    b =  cal_new.select{|k,v|k == step}
    p b 
    if b.present? 
      tmp_new << b.values().first
    else
      tmp_new << 0
    end
  end
  tmp.concat(tmp_new)
  out << tmp
end

Emailer.send_custom_file(['wudi@haihuilai.com'],  "2016年11~12月下单采购商信息", XlsGen.gen(out), "2016年11~12月下单采购商信息.xls" ).deliver

Emailer.send_custom_file(['wudi@haihuilai.com'],  "2016/2017年11~12月下单采购商信息", XlsGen.gen(out), "2016/2017年11~12月下单采购商信息.xls" ).deliver



diff_consuemr = consumers_o - consumers_n



