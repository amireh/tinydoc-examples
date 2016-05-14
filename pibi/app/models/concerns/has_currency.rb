module HasCurrency
  extend ActiveSupport::Concern

  included do
    validates :currency, with: :validate_currency
  end

  def to_global_currency
    Currency['USD'].from(Currency[self.currency], self.amount)
  end

  protected

  def to_account_currency(amount=self.amount, mine=self.currency)
    Currency[account.currency].from(Currency[mine], amount)
  end

  def validate_currency
    unless Currency[self.currency.to_s]
      errors.add :currency, "[BAD_CURRENCY] Unrecognized currency '#{self.currency}'."
    end
  end
end