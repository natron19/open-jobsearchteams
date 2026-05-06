class CreateAdvisorSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :advisor_sessions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :job_title,       null: false
      t.string :company_name,    null: false
      t.text   :job_description, null: false
      t.timestamps null: false
    end
    add_index :advisor_sessions, :created_at
  end
end
