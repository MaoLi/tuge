# Tuge Project
# author: Li Mao @copyright
# date: 2012.5
# User defination
# 

class User < ActiveRecord::Base
  
  STATUS_ANONYMOUS  = 0
  STATUS_ACTIVE     = 1
  STATUS_REGISTERED = 2
  STATUS_LOCKED     = 3


  attr_accessible :login, :name, :email, :mail_notification, :status, :last_login_on, :created_on, :updated_on, :password, :password_confirmation

  attr_accessor  :password, :password_confirmation#, :as => :admin
  attr_protected :hashed_password
  #attr_protected :login, :admin, :password, :password_confirmation, :hashed_password

  validates_presence_of :login, :name
  validates_uniqueness_of :login, :if => Proc.new { |user| !user.login.blank? }, :case_sensitive => false
  validates_uniqueness_of :email, :if => Proc.new { |user| !user.email.blank? }, :case_sensitive => false
  # Login must contain lettres, numbers, underscores only
  validates_format_of :login, :with => /^[a-z0-9_\-@\.]*$/i
  validates_length_of :login, :maximum => 30
  validates_length_of :password, :minimum => 6
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_nil => true
  validates_length_of :email, :maximum => 60, :allow_nil => true
  validates_confirmation_of :password

  scope :active, where(:status => STATUS_ACTIVE)

  before_create do |user|
    #self.mail_notification = Setting.default_notification_option if self.mail_notification.blank?
    true
  end

  before_save do |user|
    # update hashed_password if password was set
    if user.password
      user.salt_password(user.password)
    end
  end

  def active?
    self.status == STATUS_ACTIVE
  end

  def registered?
    self.status == STATUS_REGISTERED
  end

  def locked?
    self.status == STATUS_LOCKED
  end

  def activate
    self.status = STATUS_ACTIVE
  end

  def register
    self.status = STATUS_REGISTERED
  end

  def lock
    self.status = STATUS_LOCKED
  end

  def activate!
    update_attribute(:status, STATUS_ACTIVE)
  end

  def register!
    update_attribute(:status, STATUS_REGISTERED)
  end

  def lock!
    update_attribute(:status, STATUS_LOCKED)
  end
  
  def self.try_to_login(login, password)
    # Make sure no one can sign in with an empty password
    return nil if password.to_s.empty?
    user = find_by_login(login)
    if user
      # user is already in local database
      return -1 if !user.active?
      return nil unless user.check_password?(password)
    end

    user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
    user
  rescue => text
    raise text
  end

  # Find a user account by matching the exact login and then a case-insensitive
  # version.  Exact matches will be given priority.
  def self.find_by_login(login)
    # force string comparison to be case sensitive on MySQL
    type_cast = (Tuge::Database.mysql?) ? 'BINARY' : ''
    # First look for an exact match
    user = first(:conditions => ["#{type_cast} login = ?", login])
    # Fail over to case-insensitive if none was found
    user ||= first(:conditions => ["#{type_cast} LOWER(login) = ?", login.to_s.downcase])
  end

  # Returns true if +clear_password+ is the correct user's password, otherwise false
  def check_password?(clear_password)
    User.hash_password("#{salt}#{User.hash_password clear_password}") == hashed_password
  end

  # Generates a random salt and computes hashed_password for +clear_password+
  # The hashed password is stored in the following form: SHA1(salt + SHA1(password))
  def salt_password(clear_password)
    self.salt = User.generate_salt
    self.hashed_password = User.hash_password("#{salt}#{User.hash_password clear_password}")

    p "hashed password==", self.hashed_password
  end
  # Generate and set a random password.  Useful for automated user creation
  # Based on Token#generate_token_value
  #
  def random_password
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    password = ''
    40.times { |i| password << chars[rand(chars.size-1)] }
    self.password = password
    self.password_confirmation = password
    self
  end

  def to_s
    name
  end

  def self.current=(user)
    @current_user = user
  end

  def self.current
    @current_user ||= User.anonymous
  end
  # Salts all existing unsalted passwords
  # It changes password storage scheme from SHA1(password) to SHA1(salt + SHA1(password))
  # This method is used in the SaltPasswords migration and is to be kept as is
  def self.salt_unsalted_passwords!
    transaction do
      User.find_each(:conditions => "salt IS NULL OR salt = ''") do |user|
        next if user.hashed_password.blank?
        salt = User.generate_salt
        hashed_password = User.hash_password("#{salt}#{user.hashed_password}")
        User.update_all("salt = '#{salt}', hashed_password = '#{hashed_password}'", ["id = ?", user.id] )
      end
    end
  end

  protected

  def validate
    # Password length validation based on setting
    if !password.nil? && password.size < Setting.password_min_length.to_i
      errors.add(:password, :too_short, :count => Setting.password_min_length.to_i)
    end
    super
  end

  private

  # Return password digest
  def self.hash_password(clear_password)
    Digest::SHA1.hexdigest(clear_password || "")
  end

  # Returns a 128bits random salt as a hex string (32 chars long)
  def self.generate_salt
    SecureRandom.base64(15)
  end

end
