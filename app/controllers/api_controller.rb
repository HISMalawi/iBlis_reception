class ApiController < ApplicationController

  before_filter :authenticate

  require 'csv'

  def dashboard_stats

    file_name = "/tmp/orders"
    if File.exists?("#{file_name}.csv")
      data = CSV.table("#{file_name}.csv")
      result = []
      panels = []

      test_statuses = params[:test_status].split(",") rescue []

      specimen_statuses = params[:specimen_status].split(",") rescue []
      departments = params[:department].split(",") rescue []
      wards = params[:wards].split(",") rescue []

      (data).each do |d|

        #filters
        next if !test_statuses.blank? and !d[7].blank? and !test_statuses.include?(d[7])
        next if !specimen_statuses.blank? and !d[6].blank? and !specimen_statuses.include?(d[6])
        next if !departments.blank? and !d[11].blank? and !departments.include?(d[11])
        next if !wards.blank? and !d[3].blank? !wards.include?(d[3])

        #test panels
        test_name = d[8]
        if !d[10].blank? and !panels.include?(d[10])
            test_name = TestPanel.find(d[10]).panel_type.name
            panels << d[10]
        elsif  !d[10].blank? and panels.include?(d[10])
            next
        end

        result << {
                    'patient_name' => d[1],
                    'npid' => d[2],
                    'ward' => d[3],
                    'accession_number' => d[4],
                    'specimen_type_name' => d[5],
                    'specimen_status' => d[6],
                    'test_status' =>  d[7],
                    'test_type_name' => test_name,
                    'clinician' =>  d[9],
                    'panel_id' => d[10],
                    'department' => d[11],
                    'last_update_date' => d[12],
                    'date_ordered' => d[13]
                  }
      end

      render :text => result.to_json
    end
  end

  def dashboard_aggregates
    result = {
        'not-received' => 0,
        'started' => 0,
        'rejected' => 0,
        'pending' => 0,
        'completed' => 0,
        'verified' => 0
    }
    file_name = "/tmp/orders_aggregates"
    departments = params[:department].split(",") rescue []
    wards = params[:wards].split(",") rescue []

    if File.exists?("#{file_name}.csv")
      data = CSV.table("#{file_name}.csv")
      data.each do |d|
        #filters
        next if !departments.blank? and !d[2].blank? and !departments.include?(d[2])
        next if !wards.blank? and !d[3].blank? !wards.include?(d[3])

        result['not-received'] += d[4].to_i if !d[0].match(/rejected/i) and d[1].downcase.strip == 'not-received'
        result['started'] += d[4].to_i if !d[0].match(/rejected/i) and d[1].downcase.strip == 'started'
        result['rejected'] += d[4].to_i if d[0].match(/rejected/i)
        result['pending'] += d[4].to_i if !d[0].match(/rejected/i) and d[1].downcase.strip == 'pending'
        result['completed'] += d[4].to_i if !d[0].match(/rejected/i) and d[1].downcase.strip == 'completed'
        result['verified'] += d[4].to_i if !d[0].match(/rejected/i) and d[1].downcase.strip == 'verified'
      end
    end

    render :text => result.to_json
  end

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
     User.authenticate(username,password)
    end
  end

end
