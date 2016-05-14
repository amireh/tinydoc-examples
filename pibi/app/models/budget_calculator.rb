class BudgetCalculator
  attr_accessor :budget

  def initialize(budget)
    self.budget = budget
  end

  def calculate
    unless budget.context.present?
      raise 'Budget has no context!'
    end

    case budget.goal.to_s
    when 'savings_control', 'spendings_control'
      calculate_quantity
    when 'frequency_control'
      calculate_frequency
    end
  end

  private

  def calculate_quantity
    goal = if budget.ratio?
      grand_income * (budget.quantifier.to_f / 100.0)
    else
      budget.quantifier
    end

    calculate_completion_and_overflow(goal)
  end

  def calculate_frequency
    calculate_completion_and_overflow(budget.quantifier)
  end

  # The total amount of income the user has earned this budget period.
  def grand_income
    accounts = budget.user.accounts.where <<-SQL
          id != #{budget.account_id || 0}
      AND (account_type IS NULL OR account_type <> 'savings')
    SQL

    accounts.map { |scope| sum(scope, :incomes) }.sum.to_f
  end

  # Regardless of the goal type, this will return a % of the budget's goal
  # completion, and a scalar defining the overflow, if any.
  def calculate_completion_and_overflow(goal)
    tally = calculate_tally
    ratio = cap_to_hundred_percent (tally / goal.to_f) * 100.0

    {
      total: tally,
      completion: ratio.round,
      overflow: calculate_overflow(tally, goal, ratio),
      underflow: calculate_underflow(tally, goal, ratio)
    }
  end

  # Tally is calculated out of the budget's transaction set, based on the goal:
  #
  # - for deposit control it is the sum of incomes
  # - for spendings control it is the sum of expenses
  # - for frequency control it is the number of expenses, regardless of amounts
  def calculate_tally
    case budget.goal.to_s
    when 'savings_control'
      sum(budget, :incomes)
    when 'spendings_control'
      sum(budget, :expenses)
    when 'frequency_control'
      transactions_in_range(budget, :expenses).count
    end
  end

  def cap_to_hundred_percent(percentage)
    return 0 if percentage.nan?

    [ 100.0, percentage ].min
  end

  # Overflow is a scalar and not a ratio, it only makes sense in the context
  # it's interpreted in.
  def calculate_overflow(tally, goal, ratio)
    ratio == 100.0 ? tally - goal : 0
  end

  # Just like :overflow but then under!
  def calculate_underflow(tally, goal, ratio)
    ratio == 100.0 ? 0 : goal - tally
  end

  # @param [#transactions] scope
  #   Any transaction container, like an Account, a Category, or even Budget.
  #
  # @param [Symbol] type
  #   Either :incomes or :expenses.
  #
  # @return [Float] The sum of all the transactions in USD.
  def sum(scope, type)
    transactions_in_range(scope, type).map(&:to_global_currency).sum.to_f
  end

  def transactions_in_range(scope, type)
    if scope.transactions.loaded?
      typename = type == :expenses ? 'Expense' : 'Income'
      period = Range.new(*budget.period)
      scope.transactions.select do |tx|
        tx.type == typename && period.cover?(tx.occurred_on)
      end
    else
      scope.transactions.occurred_in(*budget.period).send(type)
    end
  end
end