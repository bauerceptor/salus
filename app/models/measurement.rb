# == Schema Information
#
# Table name: measurements
#
#  id                  :uuid             not null, primary key
#  is_within_limits    :boolean          default(TRUE), not null
#  measurement_date    :datetime         not null
#  value               :string           default("0.0"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#  measurement_type_id :uuid             not null
#
# Indexes
#
#  index_measurements_on_account_id           (account_id)
#  index_measurements_on_measurement_type_id  (measurement_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (measurement_type_id => measurement_types.id)
#
class Measurement < ApplicationRecord
  before_create :check_limits
  before_update :check_limits
  after_save :notify_account_of_abnormal_measurement

  belongs_to :account
  belongs_to :measurement_type

  TYPES = %i[weight heart_beat blood_pressure sugar spo2].freeze

  def value
    raw_value = super()
    if measurement_type.nil? || measurement_type.name.to_sym == :blood_pressure
      raw_value
    elsif raw_value.to_s.match?(/\A-?\d+\.?\d*\z/)
      raw_value.to_f
    else
      raw_value
    end
  end

  validates :value, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 300 },
                    on: :measurement_weight
  validates :value, numericality: { greater_than_or_equal_to: 30, less_than_or_equal_to: 220 },
                    on: :measurement_heart_beat
  validates :value, format: {
                      with: %r{\A\d{1,3}/\d{1,3}\z},
                      message: :invalid_measurement_blood_pressure
                    },
                    on: :measurement_blood_pressure
  validates :value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1000 },
                    on: :measurement_sugar
  validates :value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
                    on: :measurement_spo2

  validates :measurement_date, presence: true
  validate :measurement_date_within_3_days, on: %i[create update]

  def abnormal?
    !is_within_limits
  end

  def critical?
    return false unless measurement_type.critical_lower_limit.present? && measurement_type.critical_upper_limit.present?

    current_value = value.to_f
    critical_lower = measurement_type.critical_lower_limit.to_f
    critical_upper = measurement_type.critical_upper_limit.to_f

    current_value < critical_lower || current_value > critical_upper
  end

  def health_risk_level
    return :critical if critical?
    return :abnormal if abnormal?
    return :warning if near_limit?

    :normal
  end

  def near_limit?
    current_value = value.to_f
    lower_limit = measurement_type.lower_limit.to_f
    upper_limit = measurement_type.upper_limit.to_f

    return false if lower_limit.zero? && upper_limit.zero?

    buffer = (upper_limit - lower_limit) * 0.15

    current_value < (lower_limit + buffer) || current_value > (upper_limit - buffer)
  end

  def check_limits
    current_value = value
    lower_limit = measurement_type.lower_limit
    upper_limit = measurement_type.upper_limit

    return true if lower_limit.nil? || upper_limit.nil?

    self.is_within_limits =
      case measurement_type.name.to_sym
      when :blood_pressure
        blood_pressure_within_limits? current_value, lower_limit, upper_limit
      when :heart_beat, :sugar, :spo2
        within_limits? current_value.to_f, lower_limit.to_f, upper_limit.to_f
      else
        true
      end
  end

  def blood_pressure_within_limits?(value, lower_limit, upper_limit)
    systolic_current, diastolic_current = parse_blood_pressure value
    systolic_lower, diastolic_lower = parse_blood_pressure lower_limit
    systolic_upper, diastolic_upper = parse_blood_pressure upper_limit

    return true if systolic_current.nil? || systolic_lower.nil? || systolic_upper.nil?
    return true if diastolic_current.nil? || diastolic_lower.nil? || diastolic_upper.nil?

    within_limits?(systolic_current, systolic_lower, systolic_upper) &&
      within_limits?(diastolic_current, diastolic_lower, diastolic_upper)
  end

  def within_limits?(value, lower_limit, upper_limit)
    return true if value.nil? || lower_limit.nil? || upper_limit.nil?

    value.between?(lower_limit, upper_limit)
  end

  def parse_blood_pressure(input)
    input = input.to_s
    systolic, diastolic = input.split("/").map(&:to_f)
    [systolic, diastolic]
  end

  private

  def measurement_date_within_3_days
    return if measurement_date.blank?

    date_only = measurement_date.to_date
    today = Time.current.to_date

    if date_only > today
      errors.add(:measurement_date, :future_not_allowed)
    elsif date_only < (today - 3.days)
      errors.add(:measurement_date, :too_old)
    end
  end

  def notify_account_of_abnormal_measurement
    return unless abnormal? || critical?

    account.check_abnormal_measurement(self)
  end
end
