# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_auth('Google')
    end

    def github
      handle_auth('GitHub')
    end

    def failure
      error = params[:message] || 'unknown error'
      redirect_to new_user_session_path, alert: "OAuth failed: #{error}"
    end

    private

    def handle_auth(provider_name)
      auth = request.env['omniauth.auth']
      user = User.from_omniauth(auth)

      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
    rescue StandardError => e
      redirect_to new_user_session_path, alert: e.message
    end
  end
end
