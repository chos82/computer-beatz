class AddUsersTestData < ActiveRecord::Migration
  def self.up
    user = User.new
    user.login = 'user1' 
    user.password = 'blubba'
    user.password_confirmation = 'blubba'
    user.gender = 'male'
    user.terms = '1'
    user.email = 'ch.ossner@gmx.de'
    user.save(false)
    user.send(:activate!)
    
    user = User.new
    user.login = 'user2' 
    user.password = 'blubba'
    user.password_confirmation = 'blubba'
    user.gender = 'male'
    user.terms = '1'
    user.email = 'chossner@onlinehome.de'
    user.save(false)
    user.send(:activate!)
    
    user = User.new
    user.login = 'user3' 
    user.password = 'blubba'
    user.password_confirmation = 'blubba'
    user.gender = 'female'
    user.terms = '1'
    user.email = 'chris@computer-beatz.net'
    user.save(false)
    user.send(:activate!)
    
  end

  def self.down
    User.delete_all
  end
end
