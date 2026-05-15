class DiseaseOnboardingService
  def initialize(disease, account)
    @disease = disease
    @account = account
  end

  def group
    @disease.predefined_disease&.group
  end

  def nudge_id
    return nil unless group

    "join_group_#{group.id}"
  end

  def group_nudge_eligible?
    return false unless group
    return false if @account.group_members.exists?(group_id: group.id)
    return false if @account.nudge_dismissed?(nudge_id)

    true
  end

  def eligible_nudge
    return nil unless group_nudge_eligible?

    {
      id: nudge_id,
      group_name: group.name,
      group_id: group.id
    }
  end

  def dismiss!
    @account.dismiss_nudge!(nudge_id) if nudge_id
  end
end
