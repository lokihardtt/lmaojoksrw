class CustomFailure < Devise::FailureApp
  def redirect_url
    if warden_options[:scope] == :user 
      user = User.find_by_username(params[:user][:username]) if params[:user].present?
      if user.present?
        file = File.exists? ("public/pgp/users/#{user.id}/key.txt")
        if file.eql? true
          flash[:alert] = nil
          input_string_path(username: params[:user][:username])
        else
          new_user_session_path
        end
      else
        new_user_session_path
      end 
    else 
      new_admin_user_session_path 
    end 
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end