namespace :pibi do
  namespace :recurrings do
    desc "commits all applicable recurring transactions"
    task :commit => :outstanding do
      puts "Committing..."

      nr_committed = 0
      nr_outstanding = 0

      Recurring.where(active: true).each do |recurring|
        occurrences = recurring.outstanding_occurrences
        occurrences.length.times do
          if recurring.commit
            nr_committed += 1
          end

          recurring.reload
        end

        nr_outstanding += occurrences.length
      end

      puts "Committed #{nr_committed} out of #{nr_outstanding} outstanding bills."
    end

    desc "Outstanding recurrings that are due."
    task :outstanding => :environment do
      scope = Recurring.where(active: true).select do |recurring|
        recurring.outstanding_occurrences.any?
      end

      count = scope.reduce(0) do |sum, recurring|
        occurrences = recurring.outstanding_occurrences

        puts "Recurring##{recurring.id} '#{recurring.name}' (#{recurring.frequency}):"

        if recurring.due?
          puts "  is due on #{recurring.next_billing_date}"
        end

        if !occurrences.empty?
          puts "  has #{occurrences.length} outstanding occurrences:"
          for i in (0..occurrences.length-1) do
            puts "\t\t#{i} -> #{occurrences[i]}"
          end
        end

        sum + 1
      end

      puts "Total recurrings: #{Recurring.count}"
      puts "Total outstanding recurrings: #{count}"
    end

  end
end
