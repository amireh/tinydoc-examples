class Recurring < ActiveRecord::Base
  extend Enumerize
  include HasCurrency

  default_scope { order('name ASC') }

  WeekDays = %w[ sunday monday tuesday wednesday thursday friday saturday ]

  belongs_to :account
  belongs_to :payment_method
  has_one :user, through: :account
  has_and_belongs_to_many :categories
  has_many :attachments, as: :attachable
  has_many :transactions, dependent: :nullify

  enumerize :flow_type, in: { positive: 1, negative: 2 }, scope: true
  enumerize :frequency, in: { daily: 1, monthly: 2, yearly: 3, weekly: 4 }, scope: true

  serialize :weekly_days, Array
  serialize :monthly_days, Array
  serialize :yearly_months, Array

  validates_presence_of :name,
    message: '[RTX:MISSING_NAME] You must provide a name for this recurring.'
  validates_presence_of :every,
    message: '[RTX:MISSING_EVERY] You must provide an "every" interval quantifier.'
  validates_presence_of :frequency,
    message: "[RTX:MISSING_FREQUENCY] Frequency must be one of daily, weekly, monthly, or yearly."

  validates_presence_of :amount,
    message: '[RTX:MISSING_AMOUNT] Recurring amount is missing.'

  validates_numericality_of :amount, {
    greater_than: 0.0,
    message: '[RTX:BAD_AMOUNT] Recurring amount must be a positive number.'
  }

  validates_numericality_of :every, {
    greater_than: 0,
    message: '[RTX:BAD_EVERY] The "every" interval quantifier must be a positive integer.'
  }

  validate :functional_frequency
  validate :functional_schedule

  before_save :set_defaults

  after_initialize do
    self.created_at ||= Time.now
  end

  def context
    self.account
  end

  def journal_path
    "#{account.journal_path}/#{account.id}/recurrings"
  end

  def set_defaults
    self.every ||= 1
    self.active = true if self.active.nil?
  end

  def functional_frequency
    case (self.frequency || '').to_sym
    when :yearly
      validate_yearly_frequency
    when :monthly
      validate_monthly_frequency
    when :weekly
      validate_weekly_frequency
    end
  end

  def functional_schedule
    begin
      schedule
    rescue Exception => e
      errors.add :base, e.message
    end
  end

  def validate_yearly_frequency
    range = 1..12
    yearly_months = Array(self.yearly_months).compact.map(&:to_i)

    if yearly_day.nil?
      errors.add :yearly_day, '[RTX:MISSING_YEARLY_DAY] Missing yearly day.'
    elsif yearly_months.empty?
      errors.add :yearly_months, '[RTX:MISSING_YEARLY_MONTHS] Missing months of year.'
    elsif yearly_months.any? { |month| !range.include?(month) }
      errors.add :yearly_months, '[RTX:BAD_YEARLY_MONTHS] Months of year must range between 1 and 12.'
    elsif !(1..31).include?(self.yearly_day.to_i)
      errors.add :yearly_day, '[RTX:BAD_YEARLY_DAY] Day of year must be between 1 and 31.'
    end
  end

  def validate_monthly_frequency
    range = -1..31
    monthly_days = self.monthly_days

    if (monthly_days || []).compact.empty?
      errors.add :monthly_days, '[RTX:MISSING_MONTHLY_DAYS] Missing days of month.'
    elsif monthly_days.any? { |day| !range.include?(day.to_i) }
      errors.add :monthly_days, '[RTX:BAD_MONTHLY_DAYS] Days of month must range between -1 and 31.'
    end
  end

  def validate_weekly_frequency
    weekly_days = self.weekly_days

    if (weekly_days || []).compact.empty?
      errors.add :weekly_days, '[RTX:MISSING_WEEKLY_DAYS] Missing days of week.'
    elsif weekly_days.any? { |day| !WeekDays.include?(day.to_s) }
      errors.add :weekly_days, "[RTX:BAD_WEEKLY_DAYS] Days of week must be one or more of #{WeekDays.join(', ')}"
    end
  end

  # The time anchor on which the next commit should be based on.
  #
  # If the recurring has been committed at least once (committed_at is valid)
  # then the anchor is set to the last commit date, otherwise the anchor
  # is the date of the recurring's creation.
  #
  # @return Time object
  def commit_anchor
    zero( (committed_at || created_at).to_time )
  end

  def schedule
    s = IceCube::Schedule.new( commit_anchor )

    s.add_recurrence_rule case frequency.to_sym
    when :yearly
      IceCube::Rule.yearly(every).month_of_year(*yearly_months).day_of_month(yearly_day)
    when :monthly
      IceCube::Rule.monthly(every).day_of_month(*monthly_days)
    when :weekly
      IceCube::Rule.weekly(every).day(weekly_days.map(&:to_sym))
    when :daily
      IceCube::Rule.daily(every)
    end

    s
  end

  def next_billing_date
    zero( schedule.next_occurrence(commit_anchor) )
  end

  def outstanding_occurrences(_until = Time.now.utc)
    schedule.occurrences_between( commit_anchor+1, zero(_until) )
  end

  def zero(*args)
    if args.length == 1
      Time.utc(args[0].year, args[0].month, args[0].day)
    elsif args.length == 3
      Time.utc(*args)
    else
      Time.utc(args[0], args[1], args[2], 0, 0, 0)
    end
  end

  def due?
    next_billing_date <= zero(Time.now.utc)
  end

  def commit
    return false if !active? || !due?

    occurrence = next_billing_date

    collection = nil

    # get the transaction collection we'll be generating from/into
    collection = if flow_type.positive?
      account.incomes
    else
      account.expenses
    end

    transaction = collection.create({
      note: self.name,
      amount: self.amount,
      currency: self.currency,
      payment_method: self.payment_method,
      occurred_on: occurrence,
      categories: self.categories,
      recurring: self
    })

    unless transaction.valid?
      return false
    end

    # stamp the commit
    update({ committed_at: occurrence })

    transaction
  end
end
