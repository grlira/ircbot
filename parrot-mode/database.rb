require 'sqlite3'
require 'unicode_utils/u'
require 'unicode_utils/nfkd'
require 'unicode_utils/downcase'

module Parrot
    class Database
        BLOCK_LENGTH_WINDOW = 32
        
        def initialize(filename)
            @db = SQLite3::Database.new filename, results_as_hash: true
            # Initialize tables if necessary
            @db.execute_batch '
                CREATE TABLE IF NOT EXISTS WordAssociations (
                    first TEXT NOT NULL,
                    second TEXT NOT NULL,
                    count INTEGER NOT NULL CHECK (count >= 0),
                    
                    PRIMARY KEY (first, second)
                );
                
                CREATE TABLE IF NOT EXISTS Words (
                    word TEXT PRIMARY KEY,
                    count INTEGER NOT NULL CHECK (count >= 0)
                );
                
                CREATE TABLE IF NOT EXISTS BlockLengths (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    length INTEGER NOT NULL CHECK (length >= 0)
                );
                
                CREATE INDEX IF NOT EXISTS Assoc_Index ON WordAssociations (first, count DESC);
            '
        end
        
        # Increments the number of times in the database that word2 has been seen following word1. This count is initialized to 1 if it is not registered yet.
        def see_words(word1, word2)
            @db.execute_batch "
                INSERT OR IGNORE INTO WordAssociations VALUES (?1, ?2, 0);
                UPDATE WordAssociations SET count = count + 1 WHERE first = ?1 AND second = ?2;
            ", [word1, word2]
            @db.execute_batch "
                INSERT OR IGNORE INTO Words VALUES (?1, 0);
                UPDATE Words SET count = count + 1 WHERE word = ?1
            ", [word1]
        end
        
        # Returns a random word, weighted by the frequencies of the words that have been seen following word and drawn from the set of these words.
        def random_word_after(word)
            if limit = @db.get_first_value("SELECT count FROM Words WHERE word = ?", word)
                pick = rand limit
                @db.execute "SELECT second, count FROM WordAssociations WHERE first = ? ORDER BY count DESC", word do |record|
                    pick -= record['count']
                    return record['second'] if pick < 0
                end
            else
                # If the word has not been seen before another word yet, just pick a random word
                return @db.get_first_value "SELECT word FROM Words WHERE rowid = abs(random()) % (SELECT MAX(rowid) FROM Words) + 1"
            end
        end
        
        # Normalizes the case and combining mark representations of the given word, returning the result. 
        def normalize_word(word)
            U.downcase(U.nfkd(word))
        end
        
        def process(block)
            words = block.split(/\b\s*\b/)
            # Record this block's length
            @db.execute "INSERT INTO BlockLengths (length) VALUES (?)", words.length
            @db.execute "DELETE FROM BlockLengths WHERE id <= (SELECT MAX(id) FROM BlockLengths) - #{BLOCK_LENGTH_WINDOW}"
            words.each_cons(2) {|word1, word2| see_words normalize_word(word1), normalize_word(word2)}
        end
    end
end