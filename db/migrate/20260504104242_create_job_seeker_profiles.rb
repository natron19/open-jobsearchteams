class CreateJobSeekerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :job_seeker_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :current_role,      null: false
      t.string :target_role,       null: false
      t.text   :top_skills,        null: false
      t.text   :biggest_challenge, null: false
      t.timestamps null: false
    end
  end
end
