span = "2016-12-01".to_date.."2016-01-01".to_date



Booking.includes(:transaction, :paylog).where(:paid_at => span)
