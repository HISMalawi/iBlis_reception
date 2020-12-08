class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:user][:username],params[:user][:password])
      location = TestCategory.where(:name => params[:location_name]).first
      location_map = UserTestCategory.find_by_sql("SELECT * FROM user_testcategory  WHERE user_id = #{user.id} AND test_category_id = #{location.id}") rescue nil

      if user && !location_map.blank?
        session[:user_id] = user.id
        session[:location] = location.name
        User.current = user
        redirect_to '/' and return
      end
    end

    User.current = nil
    reset_session
  end

end
