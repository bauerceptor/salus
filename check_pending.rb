puts "Checking pending migrations..."
ctx = ActiveRecord::MigrationContext.new("db/migrate", ActiveRecord::SchemaMigration)
pending = ctx.pending_migration_versions
puts "Pending: #{pending.length}"
pending.each { |v| puts "  - #{v}" }
