require 'channel.rb'

class IrcMessage
    attr_reader :content, :nick, :command, :target, :serverName
    def initialize(line)
        parts = line.chomp.split(':')
        if line.start_with? ':'
            prefix, @command, @target = parts[1].split ' ', 3
            if @target.split.length > 1
                @target = @target.split[-1]
            end
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
            when 'JOIN'
                @kernel.channels[message.target] = Channel.new message.target
            when '353'
                @kernel.channels[message.target].add_users message.content
    	end
    end

    def handle_chat(message)
        if message.content.start_with? '!'
            handle_command(message)
        end
        case message.content
            when "hi, #{@kernel.nick}"
	            @kernel.privmsg message.target, "hello there #{message.nick}"
        end
    end

    def handle_command(message)
        case message.content.split[0]
            when "!say"
                target = message.content.split[1]
                @kernel.privmsg target, message.content.split[2..-1].join(' ') if target
            when "!users"
                channel = @kernel.channels[message.content.split[1]]
                if channel == nil
                    return
                end
                users = channel.users
                if users
                    @kernel.privmsg message.target, "In channel #{channel.name} I see users: #{users.join ' '}"
                end
            when "!join"
                channel = message.content.split[1]
                @kernel.join_channel channel if channel
            when "!part"
                channel = message.content.split[1]
                if channel
                    @kernel.part_channel channel if channel
                elsif message.target.start_with? '#'
                    @kernel.part_channel message.target.strip
                end
            when '!cycle'
                if message.target.start_with? '#'
                    @kernel.part_channel message.target.strip
                    @kernel.join_channel message.target.strip
                end
            when "!reload"
                @kernel.privmsg message.target, "Reloading handler"
                load 'handler.rb'
                @kernel.privmsg message.target, "Done"
            when "!quit"
                @kernel.disconnect

        end
    end
end
