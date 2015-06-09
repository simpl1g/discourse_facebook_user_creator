# name: facebook user creator
# about: create users from facebook id and username, attach facebook entuty
# authors: konstantin ilchenko

after_initialize do
  load File.expand_path("../controllers/facebook/users_controller.rb", __FILE__)
  load File.expand_path("../lib/facebook/user_creator.rb", __FILE__)

  Discourse::Application.routes.prepend do
    post 'facebook/users' => 'facebook/users#create'
  end
end