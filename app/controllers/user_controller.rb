class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:user][:username],params[:user][:password])
      if user
        session[:user_id] = user.id
        session[:location] = params[:location]
        User.current = user
        redirect_to '/' and return
      end
    end

    User.current = nil
    reset_session
  end

end
