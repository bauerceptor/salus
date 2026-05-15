class MedicationPolicy < ApplicationPolicy
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

  private

  def owner?
    record.account.user == user
  end
end
