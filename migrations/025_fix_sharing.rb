class FixSharing < Sequel::Migration
  def up
    alter_table :recipe_shares do
      add_column :hit_count, :integer, null: false, default: 0
      drop_column :message
      rename_column :email, :recipient
    end
  end
  
  def down
    # Tough shit
  end
end