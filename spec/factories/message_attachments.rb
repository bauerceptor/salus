FactoryBot.define do
  factory :message_attachment do
    message { nil }
    file_type { "MyString" }
    file_data { "MyString" }
    filename { "MyString" }
    content_type { "MyString" }
  end
end
