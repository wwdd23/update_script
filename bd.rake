
ids = Consumer.where(:admin_user.in => [/张海英/, "马梦龙"], :review_status => "审核通过").map(&:id)
ids = Consumer.where(:admin_user => /何霞/, :review_status => "审核通过").map(&:id);nil

a = Booking.where(:paid_at => Time.parse("2017-05-01")..Time.parse("2017-06-01"),:consumer_id.in => ids).map_reduce(
    %{
      function(){
        var consumer_name = this.consumer_name;
        var consumer_company = this.consumer_company;
        emit({name: consumer_name, company: consumer_company}, {price: this.total_rmb})
      }
    },
    %{
      function(key,items){

        var r = {price: 0};
        items.forEach(function(item){
          r.price += item.price;
        })
        return r;
      }
    }).out(:inline => true).to_a



out = [["采购商", "注册人", "责任BD", "账号类型", "订单金额", "成交订单量"]]

out1 = []
booking = Booking.where(:paid_at => Time.parse("2017-05-01")..Time.parse("2017-06-01"),)
ids.each do |n|
  consumer = Consumer.where(:id => n).first
  order = booking.where(:consumer_id => n, :status.ne => "退单完成")

  type = consumer.manager_id.present? ? "子账号" : "主账号"
  out << [consumer.company_name,  consumer.fullname, consumer.admin_user, type, order.map(&:total_rmb).reduce(:+).to_f, order.count]
  p order.map(&:total_rmb).reduce(:+).to_f
end; nil



Emailer.send_custom_file(['wudi@haihuilai.com'],  "5月销售采购商成交统计(何霞)", XlsGen.gen(out), "5月销售采购商成交统计(何霞).xls" ).deliver
