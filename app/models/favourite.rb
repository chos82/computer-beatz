class Favourite < ActiveRecord::Base
  
  belongs_to :favourizable, :polymorphic => true, :counter_cache => true
  belongs_to :user
  
end
