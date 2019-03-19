class ReleaseObserver < ActiveRecord::Observer
  
 def after_save(release)
   if release.state == 'uploaded'
     ReleaseMailer.deliver_uploaded_notification
   end
 end
 
end
