class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true, :counter_cache => true
  belongs_to :tagger, :polymorphic => true
  validates_presence_of :context
  
end