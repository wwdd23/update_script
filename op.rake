Booking.where(:$where => "(this.from_date..this.to_date).count" > 0)


Booking.where(:day_count => )


a = Booking.all.map(&:day_count).uniq.sort


Booking.all

Booking.collection.aggregate([
  {:$match => {:consumer_name => {:$not => /测试/}}},
  {:$group => {:_id => '$day_count', :count => {'$sum' => 1}}}
])


send = [["天数", "订单数"]]

a.each do |n|

  send << [n['_id'], n['count']]
end



a = Booking.collection.aggregate([
    {:$match => {:consumer_name => {:$not => /测试/}}},
    {:$project =>
      {
        :zone => '$zone',
        :date => {"$substr" => [{"$add" => ["$from_date", 8*60*60000]}, 0, 7]},
        :span => "$day_count",
      }
    },
    {:$group => 
      {:_id => 
        {
          :zone => '$zone',
          #:date => { "$dateToString" => { :format => "%Y-%m-%d",:date => {"$add" => ["$from_date", 8*60*60000]} }},
          #:date => { "$dateToString" => { :format => "%Y-%m-%d",:date => {"$add" => "$from_date"} }},
          :date => "$date",
          :span => '$span'
        }, 
        :count => {'$sum' => 1}
      }
    }

])


#
send = [["区域", '月份', '执行天数', '累计次数']]
a.each do |n|
  send << [n["_id"]["zone"], n["_id"]["date"], n["_id"]["span"], n["count"]]
end
