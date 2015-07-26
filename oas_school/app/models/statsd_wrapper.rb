# require 'nunes'
# require 'statsd'
module OasSchool
  class StatsdWrapper
    def self.statsd
      @statsd_object ||= begin
        begin
          statsd_object = $statsd
          if !statsd_object
            self.create_statsd_object

          end
          statsd_object
        rescue
          self.create_statsd_object
        end
      end
    end

    def self.create_statsd_object
      statsd_object = Statsd.new(Rails.configuration.statsd_host, Rails.configuration.statsd_port).tap{|sd| sd.namespace = "#{Rails.configuration.platform_name}.#{Rails.env}"}
      Statsd.logger = Rails.logger if Rails.configuration.statsd_debug
      Nunes.subscribe statsd_object
      statsd_object
    end

    def self.statsd_name(base, options_or_sport_code)
      if options_or_sport_code && options_or_sport_code.class == String
        sport_code = options_or_sport_code
      elsif options_or_sport_code
        sport_code = options_or_sport_code.try(:[], :sport_code) || options_or_sport_code.try(:[], 'sport_code')
      end

      base = "#{base}.#{sport_code}" if sport_code
      base
    end
  end
end
