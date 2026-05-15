class ConvertTreatmentRequestsToUuid < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE treatment_requests ADD COLUMN new_id uuid DEFAULT gen_random_uuid()"

    if ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM treatment_requests WHERE id = 0").first["count"].to_i.positive?
      execute "UPDATE treatment_requests SET new_id = gen_random_uuid() WHERE id = 0"
    end

    execute "ALTER TABLE treatment_requests DROP COLUMN id CASCADE"
    execute "DROP SEQUENCE IF EXISTS treatment_requests_id_seq"
    execute "ALTER TABLE treatment_requests RENAME COLUMN new_id TO id"
    execute "ALTER TABLE treatment_requests ALTER COLUMN id SET DEFAULT gen_random_uuid()"
    execute "ALTER TABLE treatment_requests ADD PRIMARY KEY (id)"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "UUID to bigint conversion is not reversible"
  end
end
