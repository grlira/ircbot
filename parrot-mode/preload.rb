# A script that preloads a text-profile database by reading a message at a time from a chat
# log stored in a file. Messages are held inside <message> tags. Any tags inside these are
# stripped. Common HTML entities are decoded.

require_relative 'database'

ENTITIES = {
    '&amp;' => '&',
    '&quot;' => '"',
    '&lt;' => '<',
    '&gt;' => '>',
    '&apos' => "'"
}

file = File.read ARGV[0]
db = Parrot::Database.new ARGV[1]

file.scan %r{<message.*?>(.*?)</message>} do |message,|
    message.gsub! Regexp.union(ENTITIES.keys), ENTITIES
    message.gsub!(/<.*?>/, '')
    db.process message
end