namespace :db do
  desc 'Adjusts the auto-increment sequences in ID tables (PostgreSQL-specific)'
  task :adjust_sequences => :environment do
    # basically these are the tables that get imported from legacy and may need
    # adjustment
    tables = %w[
      accounts
      categories
      payment_methods
      recurrings
      transactions
      users
    ]

    tables.each do |table|
      result = ActiveRecord::Base.connection.execute("SELECT id FROM #{table} ORDER BY id DESC LIMIT 1")

      if result.any?
        ai_val = result.first['id'].to_i + 1
        puts "Resetting auto increment ID for #{table} to #{ai_val}"
        puts "Please confirm to proceed: [Y/n]"

        if STDIN.gets.to_s =~ /n/i
          puts "Skipping."
          next
        end

        ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH #{ai_val}")
      end
    end
  end
end