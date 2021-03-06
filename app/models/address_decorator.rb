Spree::Address.class_eval do
  belongs_to :user

  scope :active, where(deleted_at: nil)

  def self.required_fields
    validator = Spree::Address.validators.find{|v| v.kind_of?(ActiveModel::Validations::PresenceValidator)}
    validator ? validator.attributes : []
  end

  # can modify an address if it's not been used in an order 
  def editable?
    new_record? || (shipments.empty? && (Spree::Order.where("bill_address_id = ?", self.id).count + Spree::Order.where("bill_address_id = ?", self.id).count <= 1) && Spree::Order.complete.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0)
  end

  def can_be_deleted?
    shipments.empty? && Spree::Order.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0
  end

  def to_s
    "#{firstname} #{lastname}: #{zipcode}, #{country}, #{state || state_name}, #{city}, #{address1} #{address2}"
    "<span style='display:inline-block;vertical-align:top;'>#{firstname} #{lastname} <br />#{address1} #{address2}<br />#{city}, #{state || state_name} #{zipcode}<br />#{country}</span>".html_safe
  end

  unless Spree::Address.new.respond_to?(:destroy_with_saving_used)
    def destroy_with_saving_used
      if can_be_deleted?
        destroy_without_saving_used
      else
        update_attribute(:deleted_at, Time.now)
      end
    end
    alias_method_chain :destroy, :saving_used
  end

end
