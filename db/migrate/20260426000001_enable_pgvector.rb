class EnablePgvector < ActiveRecord::Migration[8.0]
  def change
    enable_extension("vector") if extension_available?("vector")
  end

  private

  def extension_available?(name)
    connection.execute("SELECT 1 FROM pg_extension WHERE extname = '#{name}'").any?
  rescue PG::FeatureNotSupported
    false
  end
end
