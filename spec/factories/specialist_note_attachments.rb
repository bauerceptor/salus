FactoryBot.define do
  factory :specialist_note_attachment do
    specialist_note { nil }
    file_type { "MyString" }
    file_url { "MyString" }
    filename { "MyString" }
  end
end
