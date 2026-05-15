puts "Fixing specialist roles for accounts that have Specialist records but missing role..."

# Find all Specialist records
specialists = Specialist.all

fixed_count = 0
skipped_count = 0

specialists.each do |specialist|
  user = specialist.user

  if user.nil?
    puts "Skipping specialist #{specialist.id} - no user found"
    skipped_count += 1
    next
  end

  if user.role?("specialist")
    puts "User #{user.id} already has specialist role - skipping"
    skipped_count += 1
  else
    user.add_role("specialist")
    user.save!
    puts "Added specialist role to user #{user.id} (specialist_id: #{specialist.id})"
    fixed_count += 1
  end
end

puts "\nDone!"
puts "Fixed: #{fixed_count} accounts"
puts "Skipped: #{skipped_count} accounts"