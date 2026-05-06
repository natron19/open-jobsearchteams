class CreateAdvisorReports < ActiveRecord::Migration[8.1]
  def change
    create_table :advisor_reports, id: :uuid do |t|
      t.references :advisor_session, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.integer :fit_score,       null: false
      t.text    :rationale,       null: false
      t.text    :strengths
      t.text    :gaps
      t.string  :resume_headline
      t.text    :outreach_draft
      t.text    :gemini_raw
      t.timestamps null: false
    end
  end
end
