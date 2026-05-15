columns_to_add = {
  "image_data" => "text",
  "bio" => "text DEFAULT ''",
  "birthday" => "date",
  "education" => "varchar(50) DEFAULT ''",
  "is_hidden" => "boolean DEFAULT false",
  "is_verified" => "boolean DEFAULT false",
  "settings" => "jsonb DEFAULT '{}'",
  "sex" => "varchar(20) DEFAULT ''",
  "username" => "varchar(50)"
}

columns_to_add.each do |col, type|
  ActiveRecord::Base.connection.execute("ALTER TABLE accounts ADD COLUMN #{col} #{type}")
  puts "Added #{col}"
rescue StandardError => e
  puts "#{col}: #{e.message[0..80]}"
end
