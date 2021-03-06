module Facebook
  class UsersController < ::ApplicationController

    skip_before_filter :verify_authenticity_token, only: [:create]
    skip_before_filter :redirect_to_login_if_required, only: [:create]

    def create
      user = User.new(user_params)

      user.password = SecureRandom.hex if user.password.blank?

      if user.save
        Facebook::UserCreator.new(user, facebook_params).call

        render json: {
          success: true,
          active: user.active?,
          message: 'ok',
          user_id: user.id
        }
      else
        render json: {
          success: false,
          message: I18n.t(
            'login.errors',
            errors: user.errors.full_messages.join("\n")
          ),
          errors: user.errors.to_hash,
          values: user.attributes.slice('name', 'username', 'email')
        }
      end
    rescue ActiveRecord::StatementInvalid
      render json: {
        success: false,
        message: I18n.t("login.something_already_taken")
      }
    rescue RestClient::Forbidden
      render json: { errors: [I18n.t("discourse_hub.access_token_problem")] }
    end

    private

    def user_params
      params.permit(:name, :email, :password, :username)
            .merge(ip_address: request.remote_ip, registration_ip_address: request.remote_ip, active: true)
    end

    def facebook_params
      params.require(:facebook).permit!
    end

  end
end