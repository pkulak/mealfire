class Rating < Sequel::Model(:ratings)
  many_to_one :recipe
  updates_date_fields
end