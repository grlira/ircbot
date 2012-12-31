class IrcMessage
    attr_reader :content, :nick, :command, :target, :serverName
    def initialize(line)
        parts = line.split(':')
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
    def handle(line, kernel)
        Kernel.puts line
        message = IrcMessage.new line
        if message.command.chomp == "PRIVMSG" && message.content.chomp == "hi"
            kernel.privmsg message.target, "hello there #{message.nick}"
        end
        if message.command.chomp == "PRIVMSG" && message.content.chomp == "t"
            kernel.privmsg message.target, "your test works, #{message.nick}"
        end
        if message.command.chomp == "PING"
            kernel.write "PONG :#{message.content}"
        end
    end
end
