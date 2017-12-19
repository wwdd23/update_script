
out = [["cityid", "name",  "cityName", "citySpell",  "childseatSwitch",  "timezone",  "neighbourTip", "intownTip", "continentName",  "placeName",  "areaCode",  "location",  "dstSwitch",  "cityCode",  "cityInitial",  "cityEnName",  "enName",  "cityHotWeight",   "cityLocation",   "placeId",  "hasPrice",  "continentId"]]

YdjPoi.all.each do |n|

  out << [ 
    n["cityId"],
    n["name"],
    n["cityName"],
    n["citySpell"],
    n["childseatSwitch"],
    n["timezone"],
    n["neighbourTip"],
    n["intownTip"],
    n["continentName"],
    n["placeName"],
    n["areaCode"],
    n["location"],
    n["dstSwitch"],
    n["cityCode"],
    n["cityInitial"],
    n["cityEnName"],
    n["enName"],
    n["cityHotWeight"],
    n["cityLocation"],
    n["placeId"],
    n["hasPrice"],
    n["continentId"]]

end
Emailer.send_custom_file(['wudi@haihuilai.com'], '云地接国家城市poi信息', XlsGen.gen(out), '云地接国家城市poi信息.xls', true).deliver

