class AddBytesizeToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :bytesize, :integer
  end

  def self.down
    remove_column :items, :bytesize
  end
end
