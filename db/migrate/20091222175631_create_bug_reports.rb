class CreateBugReports < ActiveRecord::Migration
  def self.up
    create_table :bug_reports do |t|
      t.integer :member_id
      t.integer :item_id
      t.string :user_comment
      t.string :admin_comment

      t.timestamps
    end
  end

  def self.down
    drop_table :bug_reports
  end
end
