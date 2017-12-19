# 历史接送人数汇总
Booking.without_drawback.where(:paid_at => Time.parse("2017-01-01")..Time.now).map(&:people_num).reduce(:+)


# 细分接送机 包车统计
#
#
#

base = Booking.without_drawback.where(:paid_at => Time.parse("2017-01-01")..Time.now).map_reduce(
  %Q{
  function(){
    var key = this.type
    emit(key, {num: this.people_num})

  }

  },
  %Q{
  function(key, items){
    var r  = {num: 0}
    items.forEach(function(item) {
      r.num += item.num
    });
  return r;
  }
}).out(:inline => true).to_a

out = [["类型", "人数"]]
base.each do |n|
  out << [n["_id"], n["value"]["num"].to_i]
end
a = out.clone

a.shift

all_count = a.map{|n| n[1]}.reduce(:+).to_i

out << ["合计", all_count]


Emailer.send_custom_file(['wudi@haihuilai.com'],  "1-6月总服务出行人数统计", XlsGen.gen(out), "1~6月总服务出行人数统计.xls" ).deliver_now
