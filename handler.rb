require_relative 'channel'
require_relative 'user'

module IRC
    class Message
        attr_reader :content, :nick, :command, :target, :serverName
        def initialize(line)
            parts = line.chomp.split(/(?:^| ):/, 3)
            if line.start_with? ':'
                prefix, @command, @target = parts[1].split ' ', 3
                if @target && @target.split.length > 1
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
        # Returns the path to the file where this class is implemented. Required for !reload
        def self.source_location
            __FILE__
        end
        
        attr_writer :kernel

        def handle(line)
            Kernel.puts line
            message = Message.new line
        	case message.command
        	when 'PRIVMSG', 'NOTICE'
        	    handle_chat message
                when 'QUIT'
                    handle_client_quits message
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

        def handle_client_quits(message)
            @kernel.users[message.nick] = User.new(message.nick) unless @kernel.users[message.nick]
            @kernel.users[message.nick].last_message = {channel: message.target, content: nil, quit: true}
        end
        
        def handle_chat(message)
            @kernel.users[message.nick] = User.new(message.nick) unless @kernel.users[message.nick]
            @kernel.users[message.nick].last_message = {channel: message.target, content: message.content, quit: false} 
            if message.content.start_with? '!'
                handle_command(message)
            else
                handle_message(message)
            end
        end
        
        # By default, the handler does not respond to chat except for commands
        def handle_message(message); end
    
        def handle_command(message)
            components = message.content.split
            # Take out the ! symbol
            command = components.shift[1..-1]
            # Ignore unrecognized commands
            return unless respond_to? :"handle_#{command}!"
            begin
                send :"handle_#{command}!", message, *components
            # Ignore commands with the wrong arguments
            rescue ArgumentError => exception
                puts "#{exception.inspect}\n#{exception.backtrace.join "\n"}"
            end
        end
        
        # The basic commands are available for all handlers
        
        def handle_join!(message, channel_name)
            @kernel.join_channel channel_name
        end
    
        def handle_part!(message, channel_name = nil)
            if channel_name
                @kernel.part_channel channel_name
            elsif message.target.start_with? '#'
                @kernel.part_channel message.target.strip
            end
        end
    
        def handle_cycle!(message)
            if message.target.start_with? '#'
                target = message.target.strip
                @kernel.part_channel target
                @kernel.join_channel target
            end
        end
    
        def handle_reload!(message)
            @kernel.privmsg message.target, "Reloading handler"
            load self.class.source_location
            @kernel.privmsg message.target, "Done"
        end
    
        def handle_quit!(message)
            @kernel.disconnect
        end
    end
end
