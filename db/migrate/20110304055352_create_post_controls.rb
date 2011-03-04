class CreatePostControls < ActiveRecord::Migration
  def self.up
    create_table :post_controls do |t|
      t.integer :status_message_id
      t.text :content

      t.timestamps
    end
  end

  def self.down
    drop_table :post_controls
  end
end
