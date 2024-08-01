class WeatherController < ApplicationController

  # POST /weather
  def search
    redirect_to weather_path(location: params[:location])
  end

  # GET /weather
  def index
    @weather = params["location"] ? WeatherService.new.get_forecast(params["location"]) : nil

    @error = @weather[:error] if @weather.present?
  end
end
