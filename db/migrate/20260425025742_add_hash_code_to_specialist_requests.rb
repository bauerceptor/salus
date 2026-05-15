class AddHashCodeToSpecialistRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :specialist_requests, :hash_code, :string, limit: 20
    add_index :specialist_requests, :hash_code, unique: true

    SpecialistRequest.reset_column_information
    SpecialistRequest.find_each do |sr|
      sr.update!(hash_code: sr.id.split("-").first.upcase)
    end
  end
end
