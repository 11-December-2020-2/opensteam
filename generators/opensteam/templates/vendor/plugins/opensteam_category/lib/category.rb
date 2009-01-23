class Category < ActiveRecord::Base
  self.include_root_in_json = false if Category.respond_to?(:include_root_in_json)

  has_many :categories_products
  has_many :products, :through => :categories_products

  acts_as_tree :order => "name"
  named_scope :root_nodes, { :conditions => 'parent_id IS NULL' }

  class << self ;
    def find_children( id = nil )
      id.to_i == 0 ? root_nodes.first.full_set : find( id ).children
    end

    def root_nodes_hash( product = nil )
      return root_nodes.collect(&:to_hash) unless product
      return root_nodes.collect { |c| c.to_hash( product ) }
    end

  end

  def leaf ; false ; end

  def text ; "#{name} (#{children_count})"; end

  def href ; "/admin/catalog/categories/#{self.id}/edit" ; end

  def checked ; false ; end

  def children_count ; self.children.size ; end

  def to_hash( product = nil )
    h = { :text => "#{self.name} (#{self.children_count})",
      :id => self.id,
      :href => href,
      :expanded => true,
      :leaf => false,
      :iconCls => 'tree-folder-icon'
    }

    unless product
      return h.merge( :children => self.children.size > 0 ? children.collect(&:to_hash) : [] )
    else
      h.merge(
        :children => self.children.size > 0 ? children.collect { |c| c.to_hash(product) } : [],
        :checked => product.categories.include?( self )
      ) ;
    end

  end


  def product_ids=(params)
    self.products.delete_all
    self.products << Product.find( params )
  end
  

  def self_and_ancestors
    [ self, self.ancestors ].flatten.reverse
  end

  # returns the path of the current node
  def path(method = :id, str = "/" )
    "#{str}0#{str}" + self_and_ancestors.collect(&method).join(str)
  end

  def to_json_with_leaf( options = {} )
    self.to_json_without_leaf( options.merge( :methods => [:leaf, :text, :href] ) )
  end

  alias_method_chain :to_json, :leaf

end



