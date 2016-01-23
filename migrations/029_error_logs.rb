class ErrorLogs < Sequel::Migration
  def up
    create_table :error_logs do
      primary_key :id
      varchar :type
      varchar :error
      text :user
      text :request
      text :stack_trace
      boolean :completed, null: false, default: false
      boolean :invalid, null: false, default: false
      datetime :created_at, null: false
    end
    
    add_index :error_logs, :type
  end
  
  def down
    drop_table :error_logs
  end
end