class Invitation < ActiveRecord::Base
  
  belongs_to :reciever, :class_name => 'User', :foreign_key => 'reciever'
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender'
  belongs_to :group
  
  @@per_page = 15
  
end
