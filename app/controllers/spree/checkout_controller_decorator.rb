require 'exceptions'

Spree::CheckoutController.class_eval do
  
  after_filter :normalize_addresses, :only => :update
  before_filter :set_addresses, :only => :update


  # Enable address processing on the payment page.
  if Spree::AddressBook::Config[:show_bill_address_on_cc_form] == true
    before_filter :set_bill_address, :only => :update
  end

  # if the user has entered a new bill address, but it is not valid
  rescue_from Exceptions::NewBillAddressError, :with => :rescue_from_new_bill_address_error
  
  protected
  
  # set bill_address if we are on the payment page
  def set_bill_address
    return unless params[:order] && params[:state] == "payment"
    if (params[:order][:bill_address_id] && params[:order][:bill_address_id].to_i > 0) || (object_params[:bill_address_id] && object_params[:bill_address_id].to_i > 0)
      # user selected an existing address
      if (object_params[:bill_address_id] && object_params[:bill_address_id].to_i > 0)
        @order.update_attribute(:bill_address_id , object_params[:bill_address_id])
      else
        @order.update_attribute(:bill_address_id , params[:order][:bill_address_id])
      end
      params[:order].delete(:bill_address_id)
      object_params.delete(:bill_address_id)
    else
      # user has entered a new address
      @order.bill_address_attributes = params[:bill_address]
      bill_address = @order.bill_address
      if bill_address && bill_address.valid?
        @order.update_attribute_without_callbacks(:bill_address_id, bill_address.id)
        bill_address.update_attribute(:user_id, current_user.id) if current_user
        params[:order].delete(:bill_address_id)
        object_params.delete(:bill_address_id)
      else
        raise Exceptions::NewBillAddressError
      end
    end
    @order.reload
  end
  
  def set_addresses
    return unless params[:order] && params[:state] == "address"
    
    if params[:order][:ship_address_id].to_i > 0
      params[:order].delete(:ship_address_attributes)
    else
      params[:order].delete(:ship_address_id)
    end
    
    if params[:order][:bill_address_id].to_i > 0
      params[:order].delete(:bill_address_attributes)
    else
      params[:order].delete(:bill_address_id)
    end
    
  end
  
  def normalize_addresses
    return unless  params[:state] == "address" && @order.bill_address_id && @order.ship_address_id
    @order.bill_address.reload
    @order.ship_address.reload
    
    # ensure that there is no validation errors and addresses was saved
    return unless @order.bill_address && @order.ship_address
    
    if @order.bill_address_id != @order.ship_address_id && @order.bill_address.same_as?(@order.ship_address)
      @order.bill_address.destroy
      @order.update_attribute(:bill_address_id, @order.ship_address.id)
    else
      @order.bill_address.update_attribute(:user_id, current_user.try(:id))
    end
    @order.ship_address.update_attribute(:user_id, current_user.try(:id))
  end
  
  # called if user attempts to place order without accepting the legal drinking age
  def rescue_from_new_bill_address_error
    flash[:notice] = "Your billing address is not valid."
    render :edit
  end
  
end
