class PaymentMethod < ActiveRecord::Base
  include Journallable

  acts_as_journallable scope_key: 'user'

  default_scope { order('name ASC') }

  Colors = [ 'FFBB33', '99CC00', 'CC0000', '33B5E5', 'AA66CC', 'B147A3' ]

  belongs_to :user
  has_many :transactions

  before_save :set_defaults

  validates_presence_of :name,
    message: '[PMTD:MISSING_NAME] You must provide a name for the payment method.'

  validates_length_of :name, minimum: 3,
    message: '[PMTD:NAME_TOO_SHORT] A payment method must be at least 3 characters long.'

  validates_uniqueness_of :name, :scope => [ :user_id ],
    message: '[PMTD:NAME_UNAVAILABLE] You already have such a payment method.',
    case_sensitive: false

  validates :default, with: :ensure_default_uniqueness

  def set_defaults
    self.color ||= PaymentMethod.some_color
    self.default ||= false

    true
  end

  def self.some_color
    Colors[rand(Colors.size)]
  end

  private

  def ensure_default_uniqueness
    if self.default
      default_pm = self.user.default_payment_method

      if default_pm.present? && default_pm != self
        errors.add :default, 'You already have a default payment method.'
      end
    end
  end
end
