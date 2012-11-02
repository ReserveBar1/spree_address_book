Spree::Order.class_eval do

  attr_accessible :bill_address_id, :ship_address_id
  before_validation :clone_shipping_address, :if => "Spree::AddressBook::Config[:disable_bill_address]"
  
  # We need t clone the shipping address into the billing address if we are not asking for it on the address form
  # But later when we enter it on the payment form, we do not want it to be overriden with the ship address afterwards again.
  def clone_shipping_address
    if Spree::AddressBook::Config[:show_bill_address_on_cc_form] == false
      if self.ship_address
        self.bill_address = self.ship_address
      end
    else
      if self.bill_address_id == nil
        self.bill_address = self.ship_address
      end
    end
    true
  end
  
  def clone_billing_address
    if self.bill_address
      self.ship_address = self.bill_address
    end
    true
  end
  
  def bill_address_id=(id)
    address = Spree::Address.where(:id => id).first
    if address && address.user_id == self.user_id
      self["bill_address_id"] = address.id
      self.bill_address.reload
    else
      self["bill_address_id"] = nil
    end
  end
  
  def bill_address_attributes=(attributes)
    self.bill_address = update_or_create_address(attributes)
  end

  def ship_address_id=(id)
    address = Spree::Address.where(:id => id).first
    if address && address.user_id == self.user_id
      self["ship_address_id"] = address.id
      self.ship_address.reload
    else
      self["ship_address_id"] = nil
    end
  end
  
  def ship_address_attributes=(attributes)
    self.ship_address = update_or_create_address(attributes)
  end
  
  private
  
  def update_or_create_address(attributes)
    address = nil
    if attributes[:id]
      address = Spree::Address.find(attributes[:id])
      if address && address.editable?
        address.update_attributes(attributes)
      else
        attributes.delete(:id)
      end
    end
    
    if !attributes[:id]
      address = Spree::Address.new(attributes)
      address.save
    end
    
    address
  end
    
end
