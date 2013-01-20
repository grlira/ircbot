require 'sqlite3'

module Parrot
    class Database
        def initialize(filename)
            @db = SQLite3::Database.new filename, result_as_hash: true
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
    end
end