#Inventory = Opensteam::Models::Inventory

Zone = Opensteam::System::Zone

Opensteam::UserBase::User = User


module Prawnto
  module TemplateHandler
    class Base < ActionView::TemplateHandler
      def self.compilable?
        false
      end

      def compile(template)
      end
    end
  end
end





