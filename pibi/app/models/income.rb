class Income < Transaction
  def add_to_account(amount)
    account.balance += amount
  end

  def deduct(amount)
    account.balance -= amount
  end

  def +(y)
    to_account_currency + y
  end
end