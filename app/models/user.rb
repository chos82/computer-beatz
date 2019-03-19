require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :favourites, :dependent => :destroy
  has_many :music, :through => :favourites
  has_many :items, :class_name => 'Music', :foreign_key => 'created_by'
  has_many :comments, :dependent => :destroy
  has_many :permissions, :dependent => :destroy
  has_many :roles, :through => :permissions, :dependent => :destroy
  has_many :reports
  has_many :gb_outbox, :class_name => 'GuestbookEntry', :foreign_key => 'sender', :dependent => :destroy
  has_many :gb_inbox, :class_name => 'GuestbookEntry', :foreign_key => 'reciever', :dependent => :destroy
  has_many :inbox, :class_name => 'Message', :foreign_key => 'reciever', :dependent => :destroy
  has_many :outbox, :class_name => 'Message', :foreign_key => 'sender', :dependent => :destroy
  has_many :goups, :foreign_key => 'admin'
  has_many :members, :dependent => :destroy
  has_many :groups, :through => :members
  has_many :administrations, :class_name => 'Group', :foreign_key => 'admin', :dependent => :destroy
  has_many :news_messages, :foreign_key => 'sender', :dependent => :destroy
  has_many :topics
  has_many :invitations, :foreign_key => 'sender', :dependent => :destroy
  has_many :invitations, :foreign_key => 'reciever', :dependent => :destroy
  has_many :group_admin_invitations, :foreign_key => 'sender'
  has_many :group_admin_invitations, :foreign_key => 'reciever'
  has_many :projects, :through => :project_memberships
  has_many :project_memberships, :dependent => :destroy
  
  has_attached_file :avatar,
      :styles => {
      :thumb=> "40x40#",
      :small  => "124x124>",
      :original => "250x250>"},
      :url => "/system/:class/:attachment/:id/:style_:basename.:extension",
      :path => "/:rails_root/../../shared/system/:class/:attachment/:id/:style_:basename.:extension",
      :default_url => "/:class/:attachment/missing_:style.png"
      
  validates_attachment_content_type :avatar, :content_type =>[ 'image/gif', 'image/png', 'image/x-png', 'image/jpeg', 'image/pjpeg', 'image/jpg' ]
  validates_attachment_size :avatar, :less_than => 3.megabytes

  acts_as_tagger
  
  acts_as_fischyfriend
  
  has_friendly_id :login,
    :use_slug => true,
    :max_length => 50,
    :approximate_ascii => true,
    :reserved_words => ["index", "new", "auto_complete_search",
                        'search', 'advanced_search',
                         'advanced_form', 'auto_complete_login',
                         'favourites', 'tagged', 'cancel', 'memberships',
                         'account', 'friendships', 'messages', 'invitations']
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password
  
  cattr_reader :per_page
  @@per_page = 12

  validates_presence_of     :email, :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 6..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_confirmation_of :email,                      :if => Proc.new { |u| !u.email.blank? }
  validates_length_of       :login,    :within => 3..40, :if => Proc.new { |u| !u.login.blank? }
  validates_uniqueness_of   :login, :email
  validates_acceptance_of :terms
  validates_format_of :email,
                      :with => /^([^@\s]+)@.+\.+[a-z]{2,10}$/, 
                      :message => "has to be a valid email address.",
                      :if => Proc.new { |u| !u.email.blank? }
                    
  validates_format_of :www,
                      :with => /^(www\.)?.+\.+[a-z]{2,10}(\/[^\/\\]+)*\/?$/,
                      :message => "has to be a valid URI.",
                      :if => Proc.new { |u| !u.www.blank? }
  validates_inclusion_of :motto_privacy,
                         :guestbook_privacy,
                         :groups_privacy,
                         :tagged_privacy,
                         :friendships_privacy,
                         :favourites_privacy,
                         :in => %w( private friends users public )
                         
  validates_inclusion_of :gender,
                         :in => %w( male female unknown )
                      
  before_save :encrypt_password
  before_create :make_activation_code 
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  #attr_accessible :login, :email, :email_confirmation, :password, :password_confirmation, :gender, :country,
  #                :city, :zip, :terms, :www, :birthday, :time_zone, :avatar,
  #                :motto, :motto_privacy, :guestbook_privacy, :groups_privacy,
  #                :tagged_privacy, :friendships_privacy, :favourites_privacy, :no_items
  
  #as friendly_url uses attr_protected, attr_accessible can not be used 
  attr_protected :crypted_password, :salt, :activation_code
                  
  HUMANIZED_ATTRIBUTES = {
    :login => 'Username',
    :zip =>   'ZIP',
    :www =>   'Homepage'
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end 

  class ActivationCodeNotFound < StandardError; end
  class AlreadyActivated < StandardError
    attr_reader :user, :message;
    def initialize(user, message=nil)
      @message, @user = message, user
    end
  end
  
  def record_last_visit
    ActiveRecord::Base.connection.execute("update users set last_login = now() where id = #{id}")
  end
  
  def tag_counts(args = {:order => 'count'})
    args.assert_valid_keys :order
    case args[:order]
      when 'alphabetical'
        order = 'tags.name ASC'
      when 'cloud'
        order = 'taggings.created_at DESC'
      else
        order = 'count DESC'
    end
    ret = Tagging.find(:all, :joins => 'LEFT OUTER JOIN tags ON (taggings.tag_id = tags.id)',
             :select => 'tags.name AS name, COUNT(tags.id) AS count',
             :conditions => ['taggings.tagger_id = ?', id],
             :group => "tags.id",
             :order => order)
    ret.each{|x| x.count = Integer(x.count) }
  end
  
  # Finds the user with the corresponding activation code, activates their account and returns the user.
  #
  # Raises:
  #  +User::ActivationCodeNotFound+ if there is no user with the corresponding activation code
  #  +User::AlreadyActivated+ if the user with the corresponding activation code has already activated their account
  def self.find_and_activate!(activation_code)
    raise ArgumentError if activation_code.nil?
    user = find_by_activation_code(activation_code)
    raise ActivationCodeNotFound if !user
    raise AlreadyActivated.new(user) if user.active?
    user.send(:activate!)
    user
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end
  
  def self.users_online
    self.find(:all, :conditions => ["last_login > ?", 5.minutes.ago])
  end
  
  def online?
    if last_login && (Time.now - last_login)<  5.minutes
      true
    else
      false
    end
  end
  
  def is_member?(group)
    if Member.find(:first, :conditions => ["group_id = ? AND user_id = ? AND status = 'active' AND was_activated = ?", group.id, self.id, true])
      true
    else
      false
    end
  end
  
  def declined?(group)
    if Member.find(:first, :conditions => ["group_id = ? AND user_id = ? AND status = 'declined'", group.id, self.id])
      true
    else
      false
    end
  end
  
  def membership_pending?(group)
    if Member.find(:first, :conditions => ["group_id = ? AND user_id = ? AND status = 'pending'", group.id, self.id])
      true
    else
      false
    end
  end
  
  # Returns true if the user has just been activated.
  def pending?
    @activated
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ?', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end

  def reset_password
  # First update the password_reset_code before setting the
  # reset_password flag to avoid duplicate email notifications.
    update_attribute(:password_reset_code, nil)
    @reset_password = true
  end  

  #used in user_observer
  def recently_forgot_password?
    @forgotten_password
  end

  def recently_reset_password?
    @reset_password
  end

  def self.find_for_forget(email)
    find :first, :conditions => ['email = ? and activated_at IS NOT NULL', email]
  end

  def has_role?(rolename)
    self.roles.find_by_rolename(rolename) ? true : false
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def self.search( args )
    args.assert_valid_keys :query, :order,
                          :gender, :age_from,
                          :age_to, :country, :count,
                          :limit, :offset
                          
    cond = make_conditions(args[:query])
    
    unless args[:gender].blank?
      cond[0] += " AND gender = ? AND gender IS NOT NULL"
      cond << args[:gender]
    end
    unless args[:age_from].blank?
      birthday_from = Date.today - args[:age_from].to_f.years
      cond[0] += " AND birthday <= ? AND birthday IS NOT NULL"
      cond << birthday_from
    end
    unless args[:age_to].blank?
      birthday_to = Date.today- args[:age_to].to_f.years
      cond[0] += " AND birthday >= ? AND birthday IS NOT NULL"
      cond << birthday_to
    end
    unless args[:country].blank?
      cond[0] += " AND country = ? AND country IS NOT NULL"
      cond << args[:country]
    end
    
    if args[:order] == 'login'
      args[:order] = 'last_login DESC, login'
    elsif args[:order] == 'activity'
      args[:order] = 'no_items DESC, login'
    else
      args[:order] = 'login ASC'
    end
    
    objects = find( :all, :conditions => cond, :order => args[:order], :limit => args[:limit], :offset => args[:offset] )
    count = count( :all, :conditions => cond, :order => args[:order] ) if args[:count]
    
    {:objects => objects, :count => count}
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
      
    def password_required?
      crypted_password.blank? || !password.blank?
    end
    
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  
  private

  def activate!
    @activated = true
    self.update_attribute(:activated_at, Time.now.utc)
  end
  
  def self.make_conditions( query )
    cond = ['']
    if query == '*'
      return cond
    end
    tokens = []
    connectors = []
    inner_not = []
    cond[0] += '('
    iqcre = /(\s|\+|#|,|\|)/
    while query =~ iqcre do
      pos = (query =~ iqcre)
      unless pos == 0
        connectors << classify_connector( query[pos, 1] )
        tokens << query.slice(0...pos)
        query = query.slice((pos + 1)..-1)
      else
        if query[0, 1] == '#' #überflüssig?
          inner_not << 'NOT'
          query = query.slice(1..-1)
          p = query =~ iqcre
          end_con = p ? p-1 : -1
          unless end_con == -1
            connectors << classify_connector( query[(end_con +1), 1] )
            query = query.slice((end_con + 2)..-1)
          end
        end
      end
      query.strip!
    end
    tokens << query
    tokens.collect! {|c| '%' + c + '%'}
    #tokens.collect! {|c| c.strip}
    
    #construct the conditions array
     for i in 0...tokens.size do
      cond[0] +=  "login #{inner_not[i]} LIKE ? #{connectors[i]}"
      cond[0] += ' ' unless i == (tokens.size - 1)
      cond << tokens[i]
    end
    cond[0] += ')'
    cond
  end
  
  def self.classify_connector(char)
    case char
      when /[\+\s,]/
        'AND'
      when '#'
        'AND NOT'
      when '|'
        'OR'
    end
  end
  
end
