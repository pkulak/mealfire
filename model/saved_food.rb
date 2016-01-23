class SavedFood < Sequel::Model(:saved_foods)
  many_to_one :saved_list
end