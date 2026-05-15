ActiveRecord::Base.connection.execute("ALTER TABLE notes ADD COLUMN background_color varchar(20) DEFAULT ''")
puts "Added background_color to notes"
