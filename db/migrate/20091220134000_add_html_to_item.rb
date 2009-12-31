class AddHtmlToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :html, :text
  end

  def self.down
    remove_column :items, :html
  end
end
