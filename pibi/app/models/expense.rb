class Expense < Transaction
  def add_to_account(amt)
    account.balance -= amt
  end

  def deduct(amt)
    account.balance += amt
  end

  def +(y)
    to_account_currency * -1 + y
  end
end