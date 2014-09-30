require 'spec_helper'
require 'ally/io/test'
require 'pp'
require 'wunderground'
require 'date'

wday = DateTime.now.wday

weekdays = %w[
  sunday
  monday
  tuesday
  wednesday
  thursday
  friday
  saturday
]

require_relative '../lib/ally/render/weather'

plugin_settings = Ally::Foundation.get_plugin_settings('weather', 'renders')
user_settings = Ally::Foundation.get_user_settings

describe Ally::Render::Weather do

  let(:io) { Ally::Io::Test.new }
  subject { Ally::Render::Weather }

  it 'simple example' do
    ans = io.pass('whats the weather like?', subject)
    ans.should match(/^For #{user_settings[:home][:city]},/i)
  end

  it 'tomorrow\'s weather' do
    forecast = forecast(1)
    ans = io.pass('whats the weather tomorrow?', subject)
    forecast[:weekday].should match(/#{(Date.today + 1).strftime("%A")}/i)
    ans.should match(/#{forecast[:text]}$/)
  end

  it 'yesterday\'s weather' do
    history = history(DateTime.now - 1)
    ans = io.pass('what was the weather yesterday', subject)
    ans.should == history
  end

  weekdays.each_with_index do |weekday,i|
    if wday == i
      days = 7
    elsif wday < i
      days = i - wday
    elsif wday > i
      days = (7 - wday) + i
    end
    if days <= 4 # only need to check next four days
      it "check the weather for #{weekday}" do
        forecast = forecast(days)
        ans = io.pass("whats the weather #{weekday}?", subject)
        if forecast.nil?
          ans.should match(/Sorry, can't see a forecast that far in advance\./)
        else
          forecast[:weekday].should match(/#{weekday}/i)
          ans.should match(/#{forecast[:text]}$/)
        end
      end
    end
  end
end

def forecast(days)
  plugin_settings = Ally::Foundation.get_plugin_settings('weather', 'renders')
  user_settings = Ally::Foundation.get_user_settings
  w = Wunderground.new(plugin_settings[:apikey])
  zipcode = user_settings[:home][:zipcode]
  forecast = w.forecast_for(zipcode)['forecast']['txt_forecast']['forecastday']
  # forecasts are given in 12 hours cycles it seems
  period = days * 2
  if period >= forecast.length
    return nil
  else
    unit = plugin_settings[:unit]
    f = forecast[period]
    if unit.downcase == "c"
      return { weekday: f['title'], text: f['fcttext_metric']}
    else
      return { weekday: f['title'], text: f['fcttext']}
    end
  end
end

def history(date)
  plugin_settings = Ally::Foundation.get_plugin_settings('weather', 'renders')
  user_settings = Ally::Foundation.get_user_settings
  w = Wunderground.new(plugin_settings[:apikey])
  zipcode = user_settings[:home][:zipcode]
  unit = plugin_settings[:unit].downcase
  history = w.history_for(date.to_time, zipcode)
  h = history['history']['dailysummary'].first
  high_temp = unit == 'c' ? h['maxtempm'] : h['maxtempi']
  low_temp = unit == 'c' ? h['mintempm'] : h['mintempi']
  avg_temp = unit == 'c' ? h['meantempm'] : h['meantempi']
  "It was high #{high_temp} low #{low_temp}, with an avgerage of #{avg_temp} degrees."
end
