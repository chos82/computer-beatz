module MassMailer
  
require 'net/smtp'
require 'enumerator'
#require 'breakpoint'

#number of mails sent in one connection to the smtp server
SENDING_BATCH_SIZE=50

#SMTP SERVER
SMTP_SERVER='smtp.googlemail.com'

def mass_mail(recipients, message)

tmail = NewsMessageMailer.create_notification(message)

exceptions = {}
recipients.each_slice(SENDING_BATCH_SIZE) do |recipients_slice|
  Net::SMTP.start(SMTP_SERVER, 587) do |sender|
    recipients_slice.each do |recipient|
      tmail.to = recipient
      begin
        sender.send_message tmail.encoded, recipient, tmail.from
      rescue Exception => e
        exceptions[recipient] = e 
        #needed as the next mail will send command MAIL FROM, which would 
        #raise a 503 error: "Sender already given"
        sender.finish
        sender.start
      end
    end
  end
end

end

  
end