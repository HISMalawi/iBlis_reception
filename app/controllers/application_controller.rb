require 'net/ping'
require 'rubygems'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :check_logged_in, :except => ['login', 'dashboard_stats', 'dashboard_aggregates']

  before_action :check_nlims_token, :except => []

  def print_and_redirect(print_url, redirect_url, message = "Printing, please wait...", show_next_button = false, patient_id = nil)
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    @patient_id = patient_id
    render :template => 'print/print', :layout => nil
  end

  protected


  def self.up?(host)
    check = Net::Ping::External.new(host)
    check.ping?
  end

  def check_nlims_token
        configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
        settings = YAML.load_file "#{Rails.root}/config/application.yml"
        _token = File.read("#{Rails.root}/tmp/nlims_token")

        host = configs['host']
        prefix = configs['prefix']
        port = configs['port']
        protocol = configs['protocol']
        username = configs['nlims_custome_password']
        password = configs['nlims_custome_username']

        headers = {
            content_type: 'application/json',
            token: _token
        }


        if ApplicationController.up?("#{configs['nlims_service']}")
          
            url = "#{configs['nlims_controller_ip']}/api/v1/check_token_validity"
            res = JSON.parse(RestClient.get(url,headers))
            if res['error'] == true
                url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
                res = JSON.parse(RestClient.get(url,headers))
                
                if res['error'] == false
                    File.open("#{Rails.root}/tmp/nlims_token",'w'){ |t|
                        t.write(res['data']['token'])
                    }
                end

            end
        end
  end

  def check_logged_in

    if session[:user_id].blank?
      respond_to do |format|
        format.html { redirect_to '/login' }
      end
    elsif not session[:user_id].blank?
      User.current = User.where(:id => session[:user_id]).first
      #Location.current = Location.where(:name => session[:location]).first
    end
  end

end
