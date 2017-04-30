class CombineItemsInCart < ActiveRecord::Migration[5.0]
  def up
    Cart.all.each do |cart|
      sums = cart.line_items.group(:product_id).sum(:quantity)

      sums.each do |product_id, quantity|
        if quantity > 1
          cart.line_items.where(product_id: product_id).delete_all

          item = cart.line_items.build(product_id: product_id)
          item.quantity = quantity
          item.save!
        end
      end
    end
  end

  def down
    LineItem.where('quantity > 1').each do |item|
      item.quantity.times do 
        LineItem.create(
          cart_id: item.cart_id,
          product_id: item.product_id,
          quantity: 1
        )
      end
      item.destroy
    end
  end
end
