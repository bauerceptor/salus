class NotePolicy < ApplicationPolicy
  def show?
    owner?
  end

  def edit?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def pin?
    owner?
  end

  def unpin?
    owner?
  end

  private

  def owner?
    record.account.user == user
  end
end
