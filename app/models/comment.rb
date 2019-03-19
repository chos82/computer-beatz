class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true, :counter_cache => true
  belongs_to :user
  has_one :report, :as => :reportable, :dependent => :destroy
  
  validates_presence_of :text,
                        :message => "must not be empty."
  validates_length_of :text,
                      :maximum => 500,
                      :message => "must be 500 characters or less."
                      
  @@per_page = 5
  cattr_reader :per_page
  
  # used for STI models
  def commentable_type=(sType)
    if sType == Artist || sType == Track || sType == Label || sType == Album
      super(sType.to_s.classify.constantize.base_class.to_s)
    else
      super(sType.to_s.classify.constantize.to_s)
    end
  end

  
  HUMANIZED_ATTRIBUTES = {
    :text => 'Comment'
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end 

  
end
