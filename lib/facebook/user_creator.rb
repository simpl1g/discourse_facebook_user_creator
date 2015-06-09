module Facebook
  class UserCreator
    def initialize(user, params)
      @user = user
      @params = params
    end

    def call
      FacebookUserInfo.create(
        user: @user,
        facebook_user_id: @params[:uid],
        username: @params[:username],
        first_name: @params[:first_name],
        last_name: @params[:last_name],
        email: @params[:email],
        gender: @params[:gender],
        name: @params[:name],
        link: @params[:link],
      )
    end
  end
end