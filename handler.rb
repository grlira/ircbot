class IrcMessage
    attr_reader :content, :nick, :command, :target, :serverName
    def initialize(line)
        if line[0] == ':'
            hasPrefix = true
        else
            hasPrefix = false
        end

        parts = line.split(':')
        if hasPrefix
            meta = parts[1].split(' ')
            prefix = meta[0]
            @command = meta[1]
            @target = meta[2] if meta[2] != nil
            @content = parts[2]
            if prefix.split('!').length > 1
                @nick = prefix.split('!')[0]
            else
                @serverName = prefix
            end
            if target != nil
                if target[0] != '#'
                    @target = @nick
                end
            else
                @target = @nick
            end
        else
            meta = parts[0].split(' ')
            @command = meta[0]
            @target = meta[1] if meta[1] != nil
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
