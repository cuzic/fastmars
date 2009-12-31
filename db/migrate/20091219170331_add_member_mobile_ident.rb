class AddMemberMobileIdent < ActiveRecord::Migration
  def self.up
    add_column :members, :ident, :string
  end

  def self.down
    remove_column :members, :ident
  end
end
