class LargerDirections < Sequel::Migration
  def up
    DB << "alter table recipes modify directions text"
  end
end