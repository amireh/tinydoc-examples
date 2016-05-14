namespace :pibi do
  namespace :budgets do
    desc "overdue budgets"
    task :overdue => :environment do
      overdue = Budget.all.select(&:due_for_reset?)

      puts "#{overdue.length} budgets: #{overdue.map(&:id)}"
    end

    desc "reset overdue budgets"
    task :reset => :environment do
      overdue = Budget.overdue

      puts "Resetting #{overdue.length} budgets..."

      Budget.where({ id: overdue.map(&:id) }).update_all({
        resetted_at: Time.now.beginning_of_day
      })

      puts "Done."
    end
  end
end
