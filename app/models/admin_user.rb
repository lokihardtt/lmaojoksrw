class AdminUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable
  # attr_accessible :email, :username, :password, :password_confirmation, :remember_me

  attr_accessor :username

  protected
  
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    username = conditions.delete(:username)
    where(conditions).where(["lower(email) = :value", { :value => username.strip.downcase }]).first
  end
end
