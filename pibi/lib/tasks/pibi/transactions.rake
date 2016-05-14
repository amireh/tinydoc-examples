namespace :pibi do
  namespace :transactions do
    desc "Commit all outstanding transactions"
    task :commit => :outstanding do
      scope = Transaction.due_for_payment

      if scope.empty?
        next puts "\tNothing to do."
      end

      puts "Committing..."

      Transaction.transaction do
        scope.each(&:save!)
      end

      puts "Committed #{scope.reload.count} outstanding transactions."
    end

    desc "Future transactions that are now due for committing."
    task :outstanding => :environment do
      scope = Transaction.due_for_payment
      puts "Total outstanding transactions: #{scope.count}"
    end
  end
end
