class GuestbookEntry < ActiveRecord::Base
  
  belongs_to :gb_sender, :class_name => 'User', :foreign_key => 'sender'
  belongs_to :gb_reciever, :class_name => 'User', :foreign_key => 'reciever'
  
  validates_presence_of :text,
                        :message => "must not be empty."
  validates_length_of :text,
                      :maximum => 500,
                      :message => "must be 500 characters or less."
  
  cattr_reader :per_page
  @@per_page = 15
  
  def sender_login
    User.find(:first, :conditions => ["id = ?", sender]).login
  end
  
end
