namespace :pibi do
  namespace :packages do
    desc "emergency control account & budget package"
    task :emergency_control => :environment do
      puts '*' * 80
      puts "Locating users that are not equipped with the Emergency Control package..."

      users = User.where(provider: 'pibi').includes(:accounts).reject do |user|
        user.accounts.pluck(:label).include?(UserService::EMERGENCY_ACCOUNT_LABEL)
      end

      puts '-' * 80
      puts "Creating Emergency Control package for #{users.length} users."
      puts "This will take a while..."

      service = UserService.new
      count = users.length

      users.each_with_index do |user, index|
        service.create_emergency_savings_package(user)
        completion = (index / count).to_i

        if [ 10, 20, 30, 40, 50, 60, 70, 80, 90, 95 ].include?(completion)
          puts "\t#{completion}% complete..."
        end
      end

      puts "Done."
      puts '*' * 80
    end

    task :undo_emergency_control => :environment do
      puts '*' * 80
      puts "Removing the Emergency Control package from all user accounts..."

      users = User.all.includes(:accounts).select do |user|
        user.accounts.pluck(:label).include?(UserService::EMERGENCY_ACCOUNT_LABEL)
      end

      puts "#{users.length} users will be affected."

      users.each do |user|
        account = user.accounts.find_by(label: UserService::EMERGENCY_ACCOUNT_LABEL)
        budget = user.budgets.find_by(name: UserService::EMERGENCY_BUDGET_NAME)

        budget.destroy! if budget
        account.destroy! if account
      end

      puts 'Done'
      puts '*' * 80
    end
  end
end
