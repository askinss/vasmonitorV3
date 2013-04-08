class MongobrokersController < ApplicationController

  def vasresponse
    @vasresponse = Mongobroker.response_time(params["nodename"].downcase, params["span"])
    render :json => @vasresponse
  end

  def reports 
    @vasreport = Report.report_hash(params["no_of_days"],params["shortcode"],params["provisioning_type"],params['rimservice_or_shortcode']).to_json
    render :json => @vasreport
  end

  def serviceplan
    if params['subscribertype'] == 'all'
      @serviceplan = Subscriber.new.serviceplan.map { |shortcode| shortcode.to_s.gsub params['subscribertype'], "" }
    else
      @serviceplan = Subscriber.new(params['subscribertype']).serviceplan.map { |shortcode| shortcode.to_s.gsub params['subscribertype'], "" }
    end
    render :json => @serviceplan 
  end

  def shortcode
    @shortcode = Subscriber.new.shortcodes.map { |shortcode| shortcode.to_s.gsub "shortcode", "" }
    render :json => @shortcode
  end

  def provisioning_type
    @provisioning_type = Report.provisioning_type.select { |x| (x unless x.nil?) }
    render :json => @provisioning_type
  end

  private
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*' #This specifies accepting request from only localhost(127.0.0.1)
    headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS' #other http methods can be added here if there is any need to allow more than a GET request, it would be included like 'GET, POST, PUT, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*' #This specifies accepting request from only localhost(127.0.0.1)
      headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS' #other http methods can be added here if there is any need to allow more than a GET request, it would be included like 'GET, POST, PUT, OPTIONS'
      headers['Access-Control-Allow-Headers'] ='X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end
end
