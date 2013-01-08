require_relative 'channel'

class IrcMessage
    attr_reader :content, :nick, :command, :target, :serverName
    def initialize(line)
        parts = line.chomp.split(/(?:^| ):/, 3)
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
        components = message.content.split
        # Take out the ! symbol
        command = components.shift[1..-1]
        begin
            send :"handle_#{command}", message, *components unless command == 'command'
        # Ignore unrecognized handlers or commands with the wrong arguments
        rescue NoMethodError, ArgumentError => exception
            puts "#{exception.inspect}\n#{exception.backtrace.join "\n"}"
        end
    end
    
    def handle_say(message, target, *words)
        @kernel.privmsg target, words.join(' ')
    end
    
    def handle_users(message, channel_name)
        return unless channel = @kernel.channels[channel_name]
        if users = channel.users
            @kernel.privmsg message.target, "In channel #{channel.name} I see users: #{users.join ' '}"
        end
    end
    
    def handle_join(message, channel_name)
        @kernel.join_channel channel_name
    end
    
    def handle_part(message, channel_name = nil)
        if channel_name
            @kernel.part_channel channel_name
        elsif message.target.start_with? '#'
            @kernel.part_channel message.target.strip
        end
    end
    
    def handle_cycle(message)
        if message.target.start_with? '#'
            target = message.target.strip
            @kernel.part_channel target
            @kernel.join_channel target
        end
    end
    
    def handle_reload(message)
        @kernel.privmsg message.target, "Reloading handler"
        load 'handler.rb'
        @kernel.privmsg message.target, "Done"
    end
    
    def handle_quit(message)
        @kernel.disconnect
    end
end
