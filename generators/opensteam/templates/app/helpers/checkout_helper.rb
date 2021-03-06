
module CheckoutHelper

  include Opensteam::Sales::Money::Helper
  
  def fill_address_link id, address
    fields = [:firstname, :lastname, :postal, :city, :street, :country ]
    link_to_function address.full_address do |page|
      fields.each do |f|
        page["#{id}_#{f}"].value = address.send( f ).to_s
      end
      
    end
  end

  def payment_types_radio_buttons f
    Opensteam::Payment::Types.active.collect do |t|
      p = Opensteam::Payment::Base[ t.name ]

      f.radio_button( :payment_type, p.payment_id, :onclick => update_page do |page|
          page.replace_html :payment_type, :partial => "payment/#{p.payment_id}_payment", :object => p.new
        end ) +
        f.label("payment_type_#{p.payment_id}", p.display_name)
    end.join("<br />")
  end
  
  
end