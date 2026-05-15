class ChangeAttachmentUrlToText < ActiveRecord::Migration[8.1]
  def change
    change_column :messages, :attachment_url, :text
  end
end
