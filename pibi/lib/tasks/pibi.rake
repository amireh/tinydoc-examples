namespace :pibi do
  desc 'clone a set of transactions'
  task :clone_transactions => :environment do |t|
    account = Account.find_by_id(ENV['ACCOUNT_ID'])
    account.transactions.occurred_in(1.year.ago).each do |tx|
      puts "Cloning: #{tx.type}##{tx.id}";
      account.transactions.create({
        type: tx.type,
        amount: tx.amount,
        category_ids: tx.categories.map(&:id),
        note: tx.note,
        occurred_on: 1.year.from_now(tx.occurred_on)
      })
    end
  end

  desc 'run necessary tasks on outstanding resources'
  task :process => :environment do
    def run(task_id, &block)
      puts '=' * 80
      puts "Invoking rake task '#{task_id}'"
      puts '-' * 80

      task = Rake::Task[task_id.to_sym]
      task.invoke

      block.call(task) if block_given?

      puts '=' * 80
    end

    run 'pibi:currencies:update'
    run 'pibi:budgets:reset'
    run 'pibi:recurrings:commit'
    run 'pibi:transactions:commit'
  end
end