class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  rails_admin do
    list do
      field :email
      field :notify
    end
  end
end
