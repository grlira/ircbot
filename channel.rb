class Channel
    attr_accessor :users, :name, :topic

    def initialize(name)
        @users = []
        @name = name
        @topic = ''
    end

    def add_user(user)
        @users.push user
    end

    def remove_user(user)
        @users.delete user
    end

    def add_users(users)
       users.split.each do |user|
          add_user user
       end 
    end
end
