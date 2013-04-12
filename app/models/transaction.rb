class Transaction
  include Airtel
  def initialize
    @model = model
  end

  def tran(no_of_days = 1)
    #Creates an hash of the nature {:shortcode => [description,status,count]}
    #model.transaction.inject({}) { |x,y| (x[y.first.to_sym] ||= []) << y[1,3]; x }
    @model.transaction(no_of_days)
  end

  def tran_hash(no_of_days = 1)
    @model.transaction(no_of_days).inject({}) { |x,y| (x[y[1].to_sym] ||= []) << y[2,4]; x }
  end

  def shortcode_sucess_rate_hash(no_of_days = 1)
    @model.transaction_shortcode_success_rate(no_of_days).inject({}) { |x,y| (x[y[1].to_sym] ||= []) << y[2,4]; x }
  end

  def shortcode_sucess_rate(no_of_days = 1)
    @model.transaction_shortcode_success_rate(no_of_days)
  end

  def generate
    CSV.open(File.join(Rails.root, 'dumps','bbbroker_dashboard.csv'), 'ab') do |x| 
      x << %w[DATE SHORTCODE DESCRIPTION STATUS COUNT]
      tran.each { |v| x << v }
      3.times { x << [] } #add 3lines of space in between the next element
      x << %w[DATE SHORTCODE STATUS COUNT]
      shortcode_sucess_rate.each { |v| x << v }
      3.times { x << [] } #add 3lines of space in between the next element
      x << %w[DATE NODE AVERAGE_RESPONSE_TIME]
      %w[air ema rim broker].collect { |node| [node.upcase,Mongobroker.daily_average_response_time(node)]}.each { |line| x << line.unshift((Time.now - 86400).strftime("%D")) }
      @model.logoff
    end 
  end

  def logoff
    @model.logoff
  end
end
