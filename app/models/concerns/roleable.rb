module Roleable
  extend ActiveSupport::Concern

  def patient?
    roles.exists?(name: "patient")
  end

  def specialist?
    if roles.loaded?
      roles.any? { |role| role.name == "specialist" }
    else
      roles.exists?(name: "specialist")
    end
  end

  def role?(role_name)
    roles.exists?(name: role_name)
  end

  def add_role(role_name)
    role = Role.find_by(name: role_name)
    return unless role

    roles << role unless roles.include?(role)
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name)
    return unless role

    roles.delete(role)
  end

  def set_specialist_role!
    ActiveRecord::Base.transaction do
      add_role("specialist")
      create_specialist if role?("specialist") && specialist.nil?
    end
  end

  def revoke_specialist_role!
    ActiveRecord::Base.transaction do
      remove_role("specialist")
      specialist&.destroy
      self.specialist = nil
    end
  end

  def set_patient_role!
    ActiveRecord::Base.transaction do
      add_role("patient")
    end
  end
end
