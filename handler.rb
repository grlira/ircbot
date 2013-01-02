class IrcMessage
    attr_reader :content, :nick, :command, :target, :serverName
    def initialize(line)
        parts = line.chomp.split(':')
        if line.start_with? ':'
			prefix, @command, @target = parts[1].split
            @content = parts[2]
            if prefix.split('!').length > 1
                @nick = prefix.split('!')[0]
            else
                @serverName = prefix
            end
			unless @target and @target.start_with? '#'
				@target = @nick
			end
        else
			@command, @target = parts[0].split
            @content = parts[1]
        end
    end
end

class Handler

    def initialize(kernel)
        @kernel = kernel
    end

    def handle(line)
        Kernel.puts line
        message = IrcMessage.new line
		
		case message.command
			when 'PRIVMSG', 'NOTICE'
				handle_chat message
			when '433'
				@kernel.nick_in_use
			when 'PING'
				@kernel.write "PONG :#{message.content}"
		end
    end

    def handle_chat(message)
		case message.content
			when "hi, #{@kernel.nick}"
				@kernel.privmsg message.target, "hello there #{message.nick}"
			when "go away, #{@kernel.nick}"
            	@kernel.disconnect
        end
    end
end
