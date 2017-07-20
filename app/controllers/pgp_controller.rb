require 'gpgme'
require 'pty'
require 'expect'

class PgpController < ApplicationController
  before_action :authenticate_user!, except: [:input_string, :check_random_string, :check_random_string_from_profile, :confirm_new_password]
  before_action :category
  before_action :check_input_string, only: [:input_string, :input_string_from_profile, :input_string_first_time]
  before_action :find_user_with_indentifier, only: [:check_random_string, :check_random_string_from_profile, :check_random_string_first_time]

  def confirmation_change_password; end

  def change_password
    user = current_user
    new_password = SecureRandom.urlsafe_base64(10)
    session[:new_password] = new_password
    file = File.exists? ("public/pgp/users/#{current_user.id}/key.txt")
    if file.eql? true
      email = nil
      check_random_password_file = File.exists? ("public/pgp/users/#{user.id}/random_password.txt")
      if check_random_password_file.eql?false
        check_random_password_file = `touch "public/pgp/users/#{user.id}/random_password.txt"`
      else
        File.delete("public/pgp/users/#{user.id}/random_password.txt")
        check_random_password_file = `touch "public/pgp/users/#{user.id}/random_password.txt"`
      end
      url = [Rails.public_path, "/pgp/users/#{user.id}/random_password.txt"].join
      system("echo #{new_password} > #{url}")
      File.delete("public/pgp/users/#{user.id}/random_password.txt.asc") if File.exist?("public/pgp/users/#{user.id}/random_password.txt.asc")
      key = `gpg --import "public/pgp/users/#{user.id}/publickey.asc" 2>&1`
      gpg_id = key.present? ? key.split(":")[1].split().last : user.username
      random_password = `gpg --recipient #{user.username} --encrypt --armor --always-trust #{url} 2>&1`
      read_random_password = File.open("public/pgp/users/#{user.id}/random_password.txt.asc") rescue nil
      if read_random_password.nil?
        @new_password = "We are sorry you cann't do a password challenge because we cannot find a key in your profile."
      else
        @new_password = read_random_password.read.gsub(/\n/, '<br/>')
      end
    end
  end

  def confirm_new_password
    if params[:new_password].eql?(session[:new_password])
      @user = User.find(current_user.id)
      @user.password = params[:new_password]
      if @user.save
        session.delete(:new_password)
        sign_in :user,  @user, :bypass => true
        msg = "Your Password already Change"
      else
        msg = "Change Password Failed"
      end
      redirect_to edit_user_registration_path, notice: msg
    else
      redirect_to :back, alert: "PGP challenge is incorrect"
    end
  end

  def upload_key; end

  def check_pgp_key
    info = PGP.upload_key(params[:key], current_user.id)

    if info.imports
      redirect_to input_string_first_time_path
    else
      redirect_to upload_pgp_key_path, notice: "Please insert a correct a pgp key."
    end
  end

  def input_string_first_time; end

  def input_string; end

  def input_string_from_profile; end

  def check_random_string
    if @user.present?
      sign_in @user, :bypass => true
      if @user.role.eql?("Buyer")
        redirect_to dashboard_path, notice: "Signed in successfully."
      else
        redirect_to dashboard_vendor_path, notice: "Signed in successfully."
      end
    else
      redirect_to input_string_path(username: params[:username]), alert: "we are sorry your random password is incorrect"
    end
  end

  def check_random_string_from_profile
    if @user.present? && @user.id.eql?(current_user.id)
      @user.fa_pgp = true
      @user.save(validate: false)
      redirect_to edit_user_registration_url, notice: "2-Factor Authorization is Enabled"
    else
      redirect_to input_string_from_profile_url, alert: "we sorry you random password is incorrect"
    end
  end

  def check_random_string_first_time
    if @user.present? && @user.id.eql?(current_user.id)
      if current_user.role.eql?("Buyer")
        redirect_to dashboard_path, notice: "Thanks for import your pgp key"
      else
        redirect_to dashboard_vendor_path, notice: "Thanks for import your pgp key"
      end
    else
      redirect_to input_string_first_time_path(username: params[:username]), alert: "we sorry you random password is incorrect"
    end
  end

  private

  def find_user_with_indentifier
    @user = User.where(string_indentifier: params[:string_indentifier]).first
  end
  
  def check_input_string
    if current_user
      user = current_user
    else
      user = User.find_by_username(params[:username])
    end

    file = File.exists? ("public/pgp/users/#{user.id}/key.txt")
    if file.eql? true
      email = nil
      check_random_string_file = File.exists? ("public/pgp/users/#{user.id}/random_string.txt")
      if check_random_string_file
        File.delete("public/pgp/users/#{user.id}/random_string.txt") 
        File.delete("public/pgp/users/#{user.id}/random_string.txt.asc") rescue nil
      end
      random_string_file = `touch "public/pgp/users/#{user.id}/random_string.txt"`
      url = [Rails.public_path, "/pgp/users/#{user.id}/random_string.txt"].join
      user_random_string = user.string_indentifier
      system("echo #{user_random_string} > #{url}")
      # random_password_encrypt = File.exists?("public/pgp/users/#{user.id}/random_string.txt.asc")
      # if random_password_encrypt.eql?false
        key = `gpg --import "public/pgp/users/#{user.id}/publickey.asc" 2>&1`
        gpg_id = key.present? ? key.split(":")[1].split().last : user.username
        random_password = `gpg -r #{gpg_id} --encrypt --armor --always-trust #{url} 2>&1`
        read_random_string = File.open("public/pgp/users/#{user.id}/random_string.txt.asc") rescue nil
        if read_random_string.nil?
          @read_random_string = "We are sorry you can't do a password challenge because we cannot find a key in your profile."
        else
          @read_random_string = read_random_string.read.gsub(/\n/, '<br/>')
        end
      # else
      #   read_random_string = File.open("public/pgp/users/#{user.id}/random_string.txt.asc")
      #   @read_random_string = read_random_string.read.gsub(/\n/, '<br/>')
      # end
    else
      @read_random_string = "We are sorry you can't do a password challenge because we cannot find a key in your profile."
    end

  end

end