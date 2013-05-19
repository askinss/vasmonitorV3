class Monitor::Utility
  def self.load_config
    begin
      YAML.load_file File.join(Rails.root, 'config', 'monitor.yml')
    rescue TypeError => e
      Rails.logger.error e.message
      puts e.message
    end
  end
end
