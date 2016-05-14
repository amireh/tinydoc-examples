namespace :pibi do
  DEMO_EMAIL = 'demo@pibiapp.com'
  DEMO_PASSWORD = 'pibidemo123'

  desc "seeds the given user with some random data for testing"
  task :seed, [ :user_id, :date, :transaction_count ] => :demo do |t, args|
    require 'literate_randomizer'

    user_id = args[:user_id].to_s.strip
    transaction_count = [ args[:transaction_count].to_i, 10 ].max

    unless user_id.present?
      user_id = User.find_by({ email: DEMO_EMAIL }).id.to_s
    end

    year, month, day = *if args[:date].present?
      args[:date].split(/\W/).reject { |s| s.blank? }.map(&:to_i)
    else
      [ Time.now.year, nil, nil ]
    end

    user = User.find(user_id.to_s)

    rand_currency = -> {
      currencies = Currency.pluck(:name).map(&:to_s)
      currencies[rand(currencies.length)]
    }

    rand_date = -> {
      DateTime.new(*[
        year || Time.now.year,
        month || (rand(11) + 1),
        day || (rand(26) + 1)
      ])
    }

    rand_note = -> {
      LiterateRandomizer.sentence
    }

    nr_categories = user.categories.length

    transaction_service = TransactionService.new
    # some expenses
    transaction_count.times do
      transaction_service.create(user.default_account, {
        type: 'Expense',
        amount: rand(1000) + 1,
        note: rand() % 5 == 0 ? nil : rand_note.call(),
        currency: rand_currency.call(),
        occurred_on: rand_date.call(),
        payment_method: user.payment_methods[rand(user.payment_methods.length)],
        category_ids: [ user.categories[rand(nr_categories)].id ]
      })

      user.default_account.reload
    end

    transaction_count.times do
      transaction_service.create(user.default_account, {
        type: 'Income',
        amount: rand(1000) + 1,
        note: rand() % 5 == 0 ? nil : rand_note.call(),
        currency: rand_currency.call(),
        occurred_on: rand_date.call(),
        payment_method: user.payment_methods[rand(user.payment_methods.length)],
        category_ids: [ user.categories[rand(nr_categories)].id ]
      })

      user.default_account.reload
    end

    # some budgets
    budget_service = BudgetService.new

    unless user.budgets.find_by({ name: 'Saving for a Car' })
      output = budget_service.create(user, {
        "name" => "Saving for a Car",
        "goal" => "savings_control",
        "every" => 1,
        "interval" => "months",
        "icon" => "emblem-car",
        "quantifier" => 2000,
        "currency" => "USD",
        "account_id" => user.accounts.find_by({ label: 'Savings' }).id
      }.symbolize_keys)

      unless output.valid?
        puts "WARN: unable to create budget: #{output.error.to_json}"
      end
    end

    unless user.budgets.find_by({ name: 'Getting Married!' })
      output = budget_service.create(user, {
        "name" => "Getting Married!",
        "goal" => "savings_control",
        "every" => 1,
        "interval" => "months",
        "icon" => "emblem-heart",
        "quantifier" => 3000,
        "currency" => "USD",
        "account_id" => user.accounts.find_by({ label: 'Savings' }).id
      }.symbolize_keys)

      unless output.valid?
        puts "WARN: unable to create budget: #{output.error.to_json}"
      end
    end

    unless user.budgets.find_by({ name: 'Less Ice Cream' })
      output = budget_service.create(user, {
        "name" => "Less Ice Cream",
        "goal" => "spendings_control",
        "every" => 1,
        "interval" => "weeks",
        "icon" => "emblem-fun",
        "quantifier" => 100,
        "currency" => "USD",
        "category_ids" => [user.categories.find_by({ name: 'Fun' }).id]
      }.symbolize_keys)

      unless output.valid?
        puts "WARN: unable to create budget: #{output.error.to_json}"
      end
    end

  end

  task :demo => :environment do
    unless User.find_by({ email: DEMO_EMAIL })
      service = UserService.new
      rc = service.create({
        name: "Pibi Demo",
        provider: 'pibi',
        email: DEMO_EMAIL,
        password: DEMO_PASSWORD,
        password_confirmation: DEMO_PASSWORD
      })

      rc.output.accounts.create({
        label: 'Savings',
        balance: 0
      })
    end
  end

  task :remove_demo => :environment do
    user = User.find_by({ email: DEMO_EMAIL })
    service = UserService.new
    service.destroy(user)
  end
end
