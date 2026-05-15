class ChatroomsController < BaseController
  before_action :set_breadcrumbs

  def index
    @chatrooms = Chatroom.where("account1_id = ? OR account2_id = ?", current_account.id, current_account.id)
                          .includes(:account1, :account2, :chatroom_messages)
                          .order(updated_at: :desc)

    @linked_specialists = current_account.linked_specialists.to_a

    if params[:user_id].present?
      friend = Account.find(params[:user_id])
      @chatroom = find_or_create_chatroom(current_account, friend)
      @other_participant = friend
      @messages = @chatroom.chatroom_messages
                           .includes(:account)
                           .order(created_at: :asc)
                           .limit(50)
    elsif params[:id].present?
      @chatroom = Chatroom.where("account1_id = ? OR account2_id = ?", current_account.id, current_account.id).find(params[:id])
      @other_participant = @chatroom.other_participant(current_account)
      @messages = @chatroom.chatroom_messages
                           .includes(:account)
                           .order(created_at: :asc)
                           .limit(50)
    end

    if @chatroom&.persisted?
      participant = @chatroom.chatroom_participants.find_or_initialize_by(account: current_account)
      participant.last_read_at = Time.current
      participant.save if participant.new_record? || participant.changed?
    end
  end

  def show
    @chatrooms = Chatroom.where("account1_id = ? OR account2_id = ?", current_account.id, current_account.id)
                          .includes(:account1, :account2, :chatroom_messages)
                          .order(updated_at: :desc)

    @linked_specialists = current_account.linked_specialists.to_a

    @chatroom = Chatroom.where("account1_id = ? OR account2_id = ?", current_account.id, current_account.id)
                        .includes(:account1, :account2)
                        .find(params[:id])
    @other_participant = @chatroom.other_participant(current_account)
    @messages = @chatroom.chatroom_messages
                         .includes(:account)
                         .order(created_at: :asc)
                         .limit(50)

    participant = @chatroom.chatroom_participants.find_or_initialize_by(account: current_account)
    participant.last_read_at = Time.current
    participant.save if participant.new_record? || participant.changed?

    render :index
  end

  def create
    friend = Account.find(params[:user_id])
    raise ActiveRecord::RecordNotFound unless current_account.linked_specialists.map(&:account_id).include?(friend.id)

    @chatroom = find_or_create_chatroom(current_account, friend)

    redirect_to chatrooms_path(id: @chatroom.id)
  end

  private

  def find_or_create_chatroom(account1, account2)
    min_id = [account1.id, account2.id].min
    max_id = [account1.id, account2.id].max

    Chatroom.find_or_create_by(account1_id: min_id, account2_id: max_id) do |chatroom|
      chatroom.account1_id = min_id
      chatroom.account2_id = max_id
    end
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".title"), chatrooms_path
  end
end