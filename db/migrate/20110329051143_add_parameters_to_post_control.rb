class AddParametersToPostControl < ActiveRecord::Migration
  def self.up
    add_column :post_controls, :parameters, :text
  end

  def self.down
    remove_column :post_controls, :parameters
  end
end
