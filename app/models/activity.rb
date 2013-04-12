class Activity
  include Airtel
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  field :_id
  field :msisdn
  field :date_created
  field :host_ip
  field :username
  field :shortcode
  field :created_at

  def initiliaze
    @model = model
  end

  def generate
    CSV.open(File.join(Rails.root, 'dumps','activity.csv'), 'ab') do |x| 
      x << ["MSISDN","DATE_CREATED","HOST_IP","USERNAME","SHORTCODE"]
      @model.conn.exec("select activitylogger.MSISDN, activitylogger.date_created, activitylogger.HOST_IP, activitylogger.USERNAME, subscriber.shortcode from activitylogger inner join subscriber on activitylogger.MSISDN = subscriber.msisdn where activitylogger.action = 'Create new' and trunc(activitylogger.date_created) = trunc(sysdate - 1) and subscriber.shortcode LIKE '%prep'") do |row| 
        x << row
        Activity.create(msisdn: row[0],date_created: row[1], host_ip: row[2], username: row[3], shortcode: row[4])
      end
      @model.logoff
    end
  end
end
