Spree::CheckoutHelper.module_eval do
  
  def address_field(form, method, id_prefix = "b", &handler)
    content_tag :p, :id => [id_prefix, method].join('_'), :class => "field" do
      if handler
        handler.call
      else
        is_required = Spree::Address.required_fields.include?(method)
        separator = is_required ? '<span class="req">*</span><br />' : '<br />' 
        form.label(method) + separator.html_safe + 
        form.text_field(method, :class => is_required ? 'required' : nil)
      end
    end
  end
  
  def address_state(form, country)
    country ||= Spree::Country.find(Spree::Config[:default_country_id])
    have_states = !country.states.empty?
    state_elements = [
      form.collection_select(:state_id, country.states.order(:name),
                            :id, :name,
                            {:include_blank => true},
                            {:class => have_states ? "required" : "hidden",
                            :disabled => !have_states}) +
      form.text_field(:state_name,
                      :class => !have_states ? "required" : "hidden",
                      :disabled => have_states)
      ].join.gsub('"', "'").gsub("\n", "")
           
    form.label(:state, t(:state)) + '<span class="req">*</span><br />'.html_safe +
      content_tag(:noscript, form.text_field(:state_name, :class => 'required')) +
      javascript_tag("document.write(\"#{state_elements.html_safe}\");")
  end
  
  def address_as_one_liner(address)
    content_tag :span, :class => 'address_one_liner' do
      content_tag( :span, "#{address.firstname} #{address.lastname},") +
      content_tag( :span, "#{address.address1} #{address.address2},") +
      content_tag( :span, "#{address.city},") +
      content_tag( :span, "#{address.state.abbr || address.state_name} #{address.zipcode},") +
      content_tag( :span, "#{address.country}")
    end
  end
end
