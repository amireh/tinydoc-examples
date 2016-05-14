class Transaction < ActiveRecord::Base
  include Journallable
  include HasCurrency
  include Transferable

  ACCEPTED_SPLIT_FIELDS = [ :amount, :memo, :id ]

  acts_as_journallable scope_key: :accounts

  default_scope { order('occurred_on DESC') }

  belongs_to :account
  belongs_to :payment_method
  belongs_to :recurring
  has_one :user, through: :account
  has_and_belongs_to_many :categories
  has_many :attachments, as: :attachable, dependent: :destroy

  # @property [String] currency
  #
  # The transaction currency is the currency used when the transaction
  # was made, and if it differs from the account currency, the proper
  # exchange rate conversion will be made in the account balance and NOT
  # the transaction itself.
  #
  # attr_accessible :currency
  # attr_accessible :currency_rate

  def set_defaults
    self.currency = self.account.currency unless self.currency.present?
    self.currency_rate = Currency[self.currency].rate unless self.currency_rate.present?

    self.note = '' unless self.note.present?
    self.raw_occurred_on = self.occurred_on unless self.raw_occurred_on.present?
    self.splits ||= []

    unless self.payment_method.present?
      self.payment_method = self.account.user.default_payment_method
    end

    unless self.occurred_on.present?
      self.occurred_on = Time.now.utc
    end
  end

  validates_presence_of :amount,
    message: '[TX:MISSING_AMOUNT] Transaction amount is missing.'

  validates_numericality_of :amount, {
    greater_than: 0.0,
    message: '[TX:BAD_AMOUNT] Transaction amount must be a positive number.'
  }

  before_save :set_defaults

  # adjust the account balance if our amount or currency are being updated
  before_create :mark_initial_committed_status
  after_create :add_to_account_balance
  before_update :adjust_account_balance
  after_update :commit_or_uncommit
  before_destroy :deduct_from_account_balance

  scope :incomes, -> { where type: 'Income' }
  scope :expenses, -> { where type: 'Expense' }
  scope :occurred_in, ->(from, to=Time.now) { where occurred_on: (from..to) }
  scope :upcoming, -> { where('occurred_on > ?', Time.now) }
  scope :due_for_payment, -> { where('occurred_on <= ? AND committed = FALSE', Time.now) }
  scope :transfers, -> { where is_transfer: true }

  def +(y)
    y
  end

  def enforce_occurrence_resolution(dt = self.occurred_on)
    validator = Rack::API::ParameterValidators::DateValidator.new
    validator.coerce(dt, { zero: true })
  end

  def occurred_on=(dt)
    self.raw_occurred_on = dt
    super(enforce_occurrence_resolution(dt))
  end

  def deduct(amt)
  end

  def add_to_account(amt)
  end

  def context
    self.account
  end

  def splits
    Array(read_attribute(:splits)).map { |split| JSON.parse(split) }
  end

  def splits=(value)
    splits = Array(value).compact

    if splits.any? { |split| !split.is_a?(Hash) }
      return false
    end

    splits = splits.map do |split|
      split.symbolize_keys.slice(*ACCEPTED_SPLIT_FIELDS)
    end

    # bail if any amount is negative
    if splits.any? { |split| split[:amount].to_f < 0 }
      return false
    end

    tally = splits.map { |split| split[:amount].to_f }.sum

    # bail if tally is larger than our total amount, unless the transaction is
    # not yet saved, because at this point we don't have access to #amount
    unless self.amount == 0
      if tally > self.amount
        return false
      end
    end

    splits.each do |split|
      split[:id] ||= UUID.generate
    end

    write_attribute(:splits, splits.map(&:to_json))
  end

  def due?
    self.occurred_on.beginning_of_day <= Time.now.beginning_of_day
  end

  def upcoming?
    !due?
  end

  protected

  # This saves us a #reload call for newly-created transactions that are due
  # and will be committed in the after_create callback.
  def mark_initial_committed_status
    if due?
      self.committed = true
    end
  end

  def add_to_account_balance
    if due?
      add_to_account(to_account_currency)
      self.update_column(:committed, true)
      self.account.save

      true
    end
  end

  # NOOP if the transaction is not due.
  def adjust_account_balance
    return if !committed?

    if amount_changed? || currency_changed?
      # deduction:
      # the deductible amount should be what the amount and currency
      # where prior to the update *if* they were updated, technically
      # we have 4 permutations here

      dd_currency = if currency_changed?
        currency_was
      else
        self.currency
      end

      dd_amount = if amount_changed?
        amount_was
      else
        self.amount
      end

      deductible_amount = to_account_currency(dd_amount, dd_currency)
      deduct(deductible_amount)

      # update to the latest currency rate if currency has changed
      if currency_changed?
        self.currency_rate = Currency[self.currency].rate
      end

      # addition:
      # nothing special to do here since the new amount and currency
      # are set already, see #to_account_currency
      added_amount = to_account_currency
      add_to_account(added_amount)

      # note the bang (!) version; we MUST bypass all hooks here
      # since otherwise there'd be a chicken-and-egg paradox!
      #
      # (account is dirty and can't be updated because the tx itself
      #  is dirty, which needs the account to be updated, and clean, to update)
      self.account.save!
    end
  end

  def commit_or_uncommit
    # the transaction is no longer "upcoming" and it needs to be committed:
    if due? && !committed?
      if add_to_account_balance
        self.update_column(:committed, true)
      end

    # the transaction has become "upcoming" and it needs to be (un)committed:
    elsif upcoming? && committed?
      if deduct_from_account_balance
        self.update_column(:committed, false)
      end
    end
  end

  def deduct_from_account_balance
    if committed?
      deduct(to_account_currency)
      self.account.save

      true
    end
  end
end
