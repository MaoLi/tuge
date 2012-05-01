class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name,               :limit => 30

      t.column "login",             :string, :limit => 30, :default => "", :null => false
      t.column "hashed_password",   :string, :limit => 40, :default => "", :null => false

      t.column "email",             :string, :limit => 60, :default => "", :null => false
      t.column "mail_notification", :boolean, :default => false, :null => false
      t.column "admin",             :boolean, :default => false, :null => false
      t.column "status",            :integer, :default => 1, :null => false
      t.column "last_login_on",     :datetime
      t.column "language",          :string, :limit => 2, :default => ""

      t.column "created_on",        :timestamp
      t.column "updated_on",        :timestamp

      t.string "salt",              :limit => 64

      t.timestamps
    end
  end
end
