module OasSchool
  class ApplicationController < ActionController::Base
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception
    before_filter :configure_client_caching
    after_filter :set_crsf_token_for_ng

    def configure_client_caching
      expires_in 5.minutes, public: true
    end

    def simulator_mode?
      if disable_simulator_mode?
        false
      else
        Rails.configuration.try(:simulator)
      end
    end

    def disable_simulator_mode?
      Rails.configuration.try(:simulator_disabled_override)
    end


    def set_crsf_token_for_ng
      cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
    end

  protected

    def verified_request?
      super || form_authenticity_token == request.headers['X-XSRF-TOKEN']
    end
  end
end
