class User
    attr_accessor :nick, :last_message
    
    def initialize(nick)
        @nick = nick
        @last_message = nil
    end
end
