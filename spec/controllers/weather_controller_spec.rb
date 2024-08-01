require "rails_helper"

RSpec.describe WeatherController, type: :controller do
  describe "GET #search" do
    context "with valid location" do
      let(:location) { 90210 }

      it "redirects to the weather index with the location" do
        get :search, params: { location: location }
        expect(response).to redirect_to(weather_path(location: location))
      end
    end

    context "without location" do
      it "redirects to the weather index without location" do
        get :search
        expect(response).to redirect_to(weather_path)
      end
    end
  end

  describe "GET #index" do
    context "when location is provided" do
      let(:location) { 90210 }
      let(:weather_data) { { current: { temp_f: 85 } } }

      before do
        allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return(weather_data)
        get :index, params: { location: location }
      end

      it "assigns the weather data to @weather" do
        weather = controller.instance_variable_get(:@weather)
        expect(weather).to eq(weather_data)
      end
    end

    context "when location is not provided" do
      before { get :index }

      it "assigns nil to @weather" do
        weather = controller.instance_variable_get(:@weather)
        expect(weather).to be_nil
      end
    end

    context "when an error occurs" do
      let(:location) { "Unknown" }
      let(:error_data) { { error: "Location not found" } }

      before do
        allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return(error_data)
        get :index, params: { location: location }
      end

      it "assigns the error message to @error" do
        error = controller.instance_variable_get(:@error)
        expect(error).to eq("Location not found")
      end
    end
  end
end
