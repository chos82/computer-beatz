module DanielFischer
  module FischyFriends
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      def acts_as_fischyfriend
        has_many :friendships
        has_many :friendships_by_me, :foreign_key => :user_id, :class_name => "Friendship"
        has_many :friendships_for_me, :foreign_key => :friend_id, :class_name => "Friendship"
        has_many :friends_by_me,
                 :through => :friendships_by_me,
                 :source => :friendshipped_for_me
        has_many :friends_for_me, #users current user wants to be friend of
                 :through => :friendships_for_me,
                 :source => :friendshipped_by_me


        class_eval <<-EOV
          include DanielFischer::FischyFriends::InstanceMethods
        EOV
      end
    end
    
    module InstanceMethods
      
      def friendship_since(friend)
        d1 = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.id, friend])
        d2 = Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', friend, self.id])
        d1 && d2 ? ( ( d1.created_at <=> d2.created_at ) ? d2.created_at : d1.created_at ) : nil
      end
      
      def add_friend(friend)
        Friendship.create!(:user_id => self.id, :friend_id => friend.id)
      end
      
      # friendships current user requested
      def is_a_fan_of
        self.friends_by_me - self.friends_for_me
      end
      
      # friendships other users requested of current user
      def fans_of_me
        self.friends_for_me - self.friends_by_me
      end
      
      def pending_mutual_friends
        self.is_a_fan_of
      end
      
      # friends
      def mutual_friends
        (self.friends_by_me & self.friends_for_me).uniq  
      end
      
      def get_friendship_from(friend)
        Friendship.find(:first, :conditions => ['user_id = ? AND friend_id = ?', self.id, friend.id] )
      end
      
      def destroy_friendship_with(friend)
        ActiveRecord::Base.transaction do
          get_friendship_from(friend).destroy
          friend.get_friendship_from(self).destroy
        end
      end
      
      def decline_friendship_with(friend)
        friend.get_friendship_from(self).set_declined.destroy
      end
      
      # parameter-user is a friend, or at least current user requested friendship
      def is_friends_with?(friend)
        self.friends_by_me.include?(friend) ? true : false
      end
    
      # is the parameter-user a friend of me?
      def is_mutual_friends_with?(friend)
        self.is_friends_with?(friend) and friend.is_friends_with?(self) ? true : false
      end
    end
    
  end
end