class ApiController < ApplicationController

  before_filter :authenticate

  def dashboard_stats
    file_name = "/tmp/orders"
    if File.exists?("#{file_name}.csv")
      data = CSV.table("#{file_name}.csv")
      render :text => data.to_json
    end
  end

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
     User.authenticate(username,password)
    end
  end

end
