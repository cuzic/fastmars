class AddTwitterToMember < ActiveRecord::Migration
  def self.up
    add_column :members, :twitter_access_token, :string
    add_column :members, :twitter_access_token_secret, :string
  end

  def self.down
    remove_column :members, :twitter_access_token_secret
    remove_column :members, :twitter_access_token
  end
end
