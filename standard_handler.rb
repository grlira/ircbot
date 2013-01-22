require_relative 'handler'

module IRC
    class StandardHandler < Handler
        def self.source_location
            __FILE__
        end
        
        def handle_message(message)
            case message.content
                when "hi, #{@kernel.nick}"
    	            @kernel.privmsg message.target, "hello there #{message.nick}"
            end
        end
        
        def handle_say!(message, target, *words)
            @kernel.privmsg target, words.join(' ')
        end
    
        def handle_users!(message, channel_name = nil)
            channel_name = message.target.strip unless channel_name
            return unless channel = @kernel.channels[channel_name]
            if users = channel.users
                @kernel.privmsg message.target, "In channel #{channel.name} I see users: #{users.join ' '}"
            end
        end

        def handle_seen!(message, user_name)
            if user_name == message.nick
                @kernel.privmsg message.target, "Looking for yourself, #{user_name}?"
                return
            end
            return unless user = @kernel.users[user_name]
            if last_message = user.last_message
                if last_message[:quit]
                    @kernel.privmsg message.target, "I last saw #{user_name} quitting"
                else
                    @kernel.privmsg message.target, "I last saw #{user_name} in #{last_message[:channel]} saying '#{last_message[:content]}'"
                end
            end
        end
    end
end