require 'yaml'
require 'pp'

module IRC
    class Bot
        # Starts, connects and initializes an IRC bot, given a configuration file in YAML.
        def self.kickstart(config_file, handler)
            config = YAML.load(File.read(config_file))
            pp config
            config[:handler] = handler
            bot = IRC::Bot.new(config)
            bot.connect
            config[:channels].each {|channel| bot.join_channel channel}
            bot.run_main_loop
        end
    end
end