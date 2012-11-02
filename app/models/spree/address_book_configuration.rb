module Spree
  class AddressBookConfiguration < Preferences::Configuration
    preference :disable_bill_address, :boolean, :default => false
    preference :alternative_bill_address_phone, :boolean, :default => false
    preference :alternative_ship_address_phone, :boolean, :default => false
    preference :show_bill_address_on_cc_form, :boolean, :default => false
  end
end
