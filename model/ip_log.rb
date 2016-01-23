class IPLog < Sequel::Model(:ip_logs)  
  one_to_many :users
  updates_date_fields
  converts_ip_addresses
end