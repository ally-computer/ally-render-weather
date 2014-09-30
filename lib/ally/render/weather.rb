require 'ally/render'
require 'ally/render/weather/version'

module Ally
  module Render
    class Weather
      include Ally::Render

      require 'wunderground'
      require 'date'
      require 'ally/detector/date'
      require 'ally/detector/location'

      def initialize
        super # do not delete
        @keywords = %w( weather temperature outside )
        raise "Missing wunderground apikey" unless @plugin_settings.has_key?(:apikey)
        @wunderground = Wunderground.new(@plugin_settings[:apikey])
        raise "Missing zipcode config (user/home/zipcode)" unless @user_settings[:home][:zipcode]
        @zipcode = @user_settings[:home][:zipcode]
      end

      def history(datetime)
        # TODO mention weather conditions like rain, snow, thunder, tornados, etc
        resp = @wunderground.history_for(datetime.to_time, @location)
        unit = @plugin_settings[:unit].downcase
        conditions = resp['history']['dailysummary'].first
        high_temp = unit == 'c' ? conditions['maxtempm'] : conditions['maxtempi']
        low_temp = unit == 'c' ? conditions['mintempm'] : conditions['mintempi']
        avg_temp = unit == 'c' ? conditions['meantempm'] : conditions['meantempi']
        @io.say("It was high #{high_temp} low #{low_temp}, with an avgerage of #{avg_temp} degrees.")
      end

      def forecast(datetime)
        resp = @wunderground.forecast_for(@location)
        resp = Ally::Foundation.deep_symbolize(resp)
        forecasts = resp[:forecast][:txt_forecast][:forecastday]
        # see if the forecast doesn't reach the requested date
        forecast = nil
        forecasts.each do |f|
          if f[:title] =~ /^#{datetime.strftime("%A")}/i
            forecast = f
            break
          end
        end
        if forecast.nil?
          @io.say("Sorry, can't see a forecast that far in advance.")
          return nil
        end
        if @plugin_settings[:unit].downcase == 'c'
          @io.say("For #{forecast[:title]}, #{forecast[:fcttext_metric]}")
        else
          @io.say("For #{forecast[:title]}, #{forecast[:fcttext]}")
        end
      end

      def conditions
        resp = @wunderground.conditions_for(@location)
        resp = Ally::Foundation.deep_symbolize(resp)
        w = resp[:current_observation]

        status = w[:weather].downcase
        city = w[:display_location][:city]
        state = w[:display_location][:state_name]
        temp = (@plugin_settings[:unit].downcase == 'c' ? w[:temp_c] : w[:temp_f]).to_i
        unit = @plugin_settings[:unit].downcase == 'c' ? 'celsius' : 'fahrenheit'
        feels_like = (@plugin_settings[:unit].downcase == 'c' ? w[:feelslike_c] : w[:feelslike_f]).to_i
        say = "For #{city}, #{state}, "
        if @inquiry.words.include?('temperature')
          say += "Its currently #{temp} degrees #{unit}"
        else
          say += "Its currently #{status}, #{temp} degrees #{unit}"
        end
        say += ", but feels like #{feels_like}" if feels_like != temp
        @io.say(say)
      end

      def find_location
        # delete weather keywords (to not confuse place detection)
        str = @inquiry.raw
        @keywords.each { |k| str.gsub!(k, '') }
        location = Ally::Detector::Location.new(str).detect
        @location = location.nil? ? @zipcode : location
      end

      def process(inquiry, io)
        @io = io
        @inquiry = inquiry
        location = find_location
        datetime = Ally::Detector::Date.new(@inquiry.raw).detect
        if datetime.nil?
          conditions
        else
          diff = datetime.to_time.to_i - Time.now.to_i
          if diff.abs <= 300
            # datetime within 300 seconds, assuming they want current conditions
            conditions
          elsif diff > 0
            forecast(datetime)
          else
            history(datetime)
          end
        end
      end
    end
  end
end
