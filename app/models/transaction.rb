class Transaction
  include Airtel

  def tran
    #Creates an hash of the nature {:shortcode => [description,status,count]}
    #model.transaction.inject({}) { |x,y| (x[y.first.to_sym] ||= []) << y[1,3]; x }
    model.transaction
  end

  def shortcode_sucess_rate
    model.transaction_shortcode_success_rate.sort
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
    end 
  end
end
