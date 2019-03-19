class Member < ActiveRecord::Base
  
  belongs_to :group
  belongs_to :user
  
  @@per_page = 20
  
 validates_inclusion_of :status,
    :in => %w{ active pending declined canceled },
    :message => "is not valid."
  
  def pending?
    if self.status == 'pending'
      true
    else
      false
    end
  end
  
  def recently_activated?
    if self.status == 'active' && self.was_activated == false
      true
    else
      false
    end
  end
  
  def declined?
    if self.status == 'declined' && self.was_activated == false
      true
    else
      false
    end
  end
  
  def canceled?
    if self.status == 'canceled'
      true
    else
      false
    end
  end
  
end
