url = "http://www.haihuilai.com/api"


header = {
  "Accept":"*/*",
  "Content-Type":"application/x-www-form-urlencoded",
  "Origin":"http://www.travelnote.com.cn",
  //"Referer":"http://www.travelnote.com.cn/seoul/hotel/seaes/reservation",
  "Referer": url,
  "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36",
  "X-Requested-With":"XMLHttpRequest",
}



request.post({url:url , headers: header, form: data  }


date = ["2016-12-01", "2017-02-01"]

date.each do |n|

  data = {
    "date": n,
    "from_city_id": 123,
    "to_city_id": 1245,
  }



end
