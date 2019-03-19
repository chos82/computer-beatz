class Message < ActiveRecord::Base
  
  belongs_to :reciever, :class_name => 'User', :foreign_key => 'reciever'
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender'
  
  validates_presence_of :text,
                        :message => "must not be empty."
  validates_length_of :text,
                      :maximum => 3000,
                      :message => "must be 3000 characters or less."
                      
  validates_presence_of :subject,
                        :message => "must not be empty."
  validates_length_of :subject,
                      :maximum => 255,
                      :message => "must be 255 characters or less."
                      
  @@per_page = 15
  
end
