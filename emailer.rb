#encoding: utf-8

class Emailer < ActionMailer::Base
  #default from: "qwb-data@mail.haihuilai.com"
  default from: "admin@haihuilai.com"
  
  #default bcc: ['wudi@haihuilai.com']

  def send_custom_file(email, subject, file_content, file_name = 'attach_file', is_compress = false)

    new_file_name = file_name

    if is_compress
      buffer = Zip::OutputStream.write_buffer do |out|
        out.put_next_entry(file_name)
        out.write(file_content)
      end.string

      new_file_name.concat(".zip")
    else
      buffer = file_content
    end

    attachments[new_file_name] = {
      mime_type: "application/octet-stream",
      content: buffer
    }

    mail(:subject => subject, to: email) do |format|
      format.html { render :text => '见附件'}
    end
  end

  def rater_edm_20150929(email,nickname)
    Dir.glob(File.join(Rails.root, 'app/images/misc_mailers/rater_edm_20150929/*')).each do |file|
      next if file =~ /edm_qrcode2.png/
      next if file =~ /edm_btn_dlapp.png/
      attachments.inline[File.basename(file)] = File.read(file)
    end
    subject = "写点评，分享入住体验，领最高30元返现"
    @nickname = nickname
    mail(to: email, subject: subject ) do |format|
      format.html { render layout: false }
    end
  end

  def thank_for_consumer(email)
    Dir.glob(File.join(Rails.root, 'app/images/misc_mailers/thank_for_consumer/*')).each do |file|
      #next if file =~ /1.jpg/
      #next if file =~ /4.jpg/
      attachments.inline[File.basename(file)] = File.read(file)
    end
    subject = "还会来12月份大促"
    attachments['“圣诞劫”,抢礼物喽!.docx'] = {
      mime_type: "application/octet-stream",
      content: File.read('app/images/misc_mailers/attachs/“圣诞劫”,抢礼物喽!.docx')
    }
    attachments['还会来2016年感恩真情相伴，现金返还活动.docx'] = {
      mime_type: "application/octet-stream",
      content: File.read('app/images/misc_mailers/attachs/还会来2016年感恩真情相伴，现金返还活动.docx')
    }
    mail(to: email, subject: subject ) do |format|
      format.html { render layout: false }
    end
  end

end
