module ApplicationHelper
  include Pagy::Frontend

  CURRENT_LOGO = "salus-with-name".freeze
  CURRENT_LOGO_ICON = "salus-without-name".freeze

  def role_specialist?(user)
    user.specialist?
  end

  def current_account
    @current_account ||= current_user&.account
  end

  def user_image
    return unless current_user

    return unless current_account.image

    current_account.image.url
  end

  def user_initials
    return unless current_account

    first = current_account.first_name&.first || ""
    last = current_account.last_name&.first || ""
    (first + last).upcase.presence || current_account.username&.first&.upcase || "?"
  end

  def user_has_image?
    current_account&.image.present?
  end

  def account_initials(account)
    return "?" unless account

    first = account.first_name&.first || ""
    last = account.last_name&.first || ""
    (first + last).upcase.presence || account.username&.first&.upcase || "?"
  end

  def account_has_image?(account)
    account&.image.present?
  end

  def account_image_tag(account, options = {})
    if account_has_image?(account) && account.image.attached?
      image_tag(account.image.url, options)
    else
      tag.span(account_initials(account), options.merge(class: "avatar-initials"))
    end
  end

  def user_full_name
    return unless current_user

    "#{current_account.first_name} #{current_account.last_name}"
  end

  def user_username
    return unless current_user

    "@#{current_account.username}"
  end

  def intensity_to_emoji(intensity)
    case intensity
    when 1
      "🙂"
    when 2
      "😐"
    when 3
      "🙁"
    when 4
      "😢"
    when 5
      "😫"
    else
      "😡"
    end
  end

  def effectiveness_to_emoji(intensity)
    case intensity
    when 1
      "😫 Not effective"
    when 2
      "🙁 Doesn't help"
    when 3
      "😐 Somewhat helpful"
    when 4
      "🙂 Helpful"
    when 5
      "😀 Very helpful"
    else
      "😡"
    end
  end

  def localized_logo_image_tag(options = {})
    logo_name = "#{CURRENT_LOGO}.svg"
    image_tag logo_name, options.merge(alt: "Salus Logo")
  end

  def logo_icon_tag(options = {})
    logo_name = "#{CURRENT_LOGO_ICON}.svg"
    image_tag logo_name, options.merge(alt: "Salus Icon")
  end

  def notification_icon(type)
    case type
    when "medication_reminder"
      "ri-pill-line"
    when "measurement_alert", "measurement_reminder"
      "ri-heart-pulse-line"
    when "appointment_reminder"
      "ri-calendar-event-line"
    when "emergency_alert"
      "ri-emergency-warning-line"
    when "message"
      "ri-chat-3-line"
    when "group_activity"
      "ri-group-line"
    when "achievement"
      "ri-award-line"
    when "doctor_note"
      "ri-file-text-line"
    when "friend_request"
      "ri-user-add-line"
    when "general"
      "ri-information-line"
    else
      "ri-notification-3-line"
    end
  end

  def alert_class_for(type)
    case type.to_s
    when "alert" then "danger"
    when "notice" then "success"
    when "error" then "danger"
    when "info" then "info"
    else "info"
    end
  end

  def alert_icon_for(type)
    case type.to_s
    when "alert" then "alert-line"
    when "notice" then "checkbox-circle-line"
    when "error" then "error-warning-line"
    when "info" then "information-line"
    else "information-line"
    end
  end
end
