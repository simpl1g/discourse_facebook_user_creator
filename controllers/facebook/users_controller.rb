module Facebook
  class UsersController < ::ApplicationController

    skip_before_filter :verify_authenticity_token, only: [:create]
    skip_before_filter :redirect_to_login_if_required, only: [:create]

    def create
      params.permit(:user_fields)

      unless SiteSetting.allow_new_registrations
        return fail_with("login.new_registrations_disabled")
      end

      if params[:password] && params[:password].length > User.max_password_length
        return fail_with("login.password_too_long")
      end

      user = User.new(user_params)

      # Handle custom fields
      user_fields = UserField.all
      if user_fields.present?
        field_params = params[:user_fields] || {}
        fields = user.custom_fields

        user_fields.each do |f|
          field_val = field_params[f.id.to_s]
          if field_val.blank?
            return fail_with("login.missing_user_field") if f.required?
          else
            fields["user_field_#{f.id}"] = field_val[0...UserField.max_length]
          end
        end

        user.custom_fields = fields
      end

      user.password = SecureRandom.hex if user.password.blank?

      if user.save
        activation.finish
        Facebook::UserCreator.new(user, facebook_params).call

        # save user email in session, to show on account-created page
        session["user_created_message"] = activation.message

        render json: {
          success: true,
          active: user.active?,
          message: activation.message,
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

  end
end