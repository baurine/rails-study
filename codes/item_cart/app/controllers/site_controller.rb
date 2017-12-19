class SiteController < ApplicationController
  def index
    
  end

  def items
    @items = Item.first(3)
  end
end