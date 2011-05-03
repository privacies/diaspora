class CreateThirdPartyUserTokens < ActiveRecord::Migration
  def self.up
    create_table :third_party_user_tokens do |t|
      t.string :value
      t.integer :person_id

      t.timestamps
    end
  end

  def self.down
    drop_table :third_party_user_tokens
  end
end
