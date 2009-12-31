class CreateItemMembers < ActiveRecord::Migration
  def self.up
    create_table :item_members do |t|
      t.integer :item_id
      t.integer :member_id
      t.integer :view_count, :default => 0

      t.timestamps
    end
    add_index :item_members, :item_id
    add_index :item_members, :member_id
  end

  def self.down
    drop_table :item_members
  end
end
