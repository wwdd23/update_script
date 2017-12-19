# 查询线上log 正则获取log信息
date = Time.now.yesterday.to_date.to_s

grep " place_autocomplete" production.log | awk -F ':' '{print $2}'

exec `grep "place_autocomplete" db/production.log | grep #{data}`

exec `grep #{date} db/production.log | grep "place_autocomplete code"`

a = %x{ grep #{date} db/production.log | grep "place_autocomplete code" | awk -F 'place_autocomplete code' '{print $2}' | awk -F':' '{print "\{:key\=\>" $2 ",:val\=\>" $4 "\}"}' }



grep " place_autocomplete" production.log | awk -F 'place_autocomplete code' '{print $2}' > awk_list

cat awk_list | awk -F':' '{print $2 ";" $4}'

a = %x{grep " place_autocomplete" production.log | awk -F 'place_autocomplete code' '{print $2}' | awk -F':' '{print $2 ";" $4}'}

cat awk_list | awk -F':' '{print $2 ";" $4}'

a = %x{ grep #{date} db/production.log | grep "place_autocomplete code" | awk -F 'place_autocomplete code' '{print $2}' | awk -F':' '{print "\{:key\=\>" $2 ",:val\=\>" $4 "\}"}' }



grep "place_autocomplete code" production.log| awk -F 'place_autocomplete code' '{print $2}' | awk -F':' '{print "\{:key\=\>" $2 ",:val\=\>" $4 "\}"}'

grep " place_autocomplete code" production.log | awk -F ':' '{print "\{:key\=\>" $5 ",:val\=\>" $7 "\}"}'



a = %x{ grep #{date} db/production.log |  grep "place_autocomplete code" | awk -F ':' '{print "\{:key\=\>" $5 ",:val\=\>" $7 "\}"}'}


a = %x{ grep #{date} db/production.log |  grep "place_autocomplete code" | awk -F ':' '{print  $5 ";" $7 }'}

send = []
a.each_line do |n|
  data =  n.split(";")
  send << {:key => data[0],:val => data[1].chomp }
end
