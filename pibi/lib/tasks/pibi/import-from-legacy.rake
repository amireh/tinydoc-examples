require 'fileutils'

namespace :pibi do
  desc 'import data from legacy Pibi 2.0 schema JSON dump'
  task :import_from_legacy, [:path, :blacklist_path] => [:environment] do |task, args|
    @failures = []
    @currencies = Currency.all.map(&:name)

    @blacklist = begin
      JSON.parse(File.read(args[:blacklist_path]))
    rescue
      {}
    end

    def blacklisted?(resource_type, id)
      return (@blacklist[resource_type.to_s] || []).include?(id)
    end

    def guard(data, &block)
      begin
        block.call
      rescue ActiveRecord::RecordNotFound => e
        puts "Failed to import: #{data}"
        puts "Cause: #{e.message}"
        @failures << { data: data, error: e.message }
      rescue Exception => e
        @failures << { data: data, error: e.message }
        raise e unless ENV['DESPERATE']
      end
    end

    def fix_currency(data)
      data['currency'] ||= ''

      unless @currencies.include?(data['currency'])
        puts "[WARN] Bad currency: #{data['currency']}, attempting to amend..."

        currency_rate = data['currency_rate'] || 1.0
        candidates = Currency.where({ rate: currency_rate })
        currency = candidates.detect { |c| c.name.match data['currency'] }

        if currency
          puts "\tFound possible currency: #{currency}, adjusting transaction."
          data['currency'] = currency.name
          data['currency_rate'] = currency.rate
        end
      end
    end

    # User data:
    #
    #   * id
    #   * name
    #   * provider
    #   * uid
    #   * password
    #   * email
    #   * email_verified
    #   * settings
    #   * auto_password
    #   * created_at
    #   * link_id
    def import_user(data)
      puts "\tUser#{data['id']}: #{data['email']} (#{data['provider']})"

      user = User.new
      user.id = data['id']
      user.uid = data['uid']
      user.provider = data['provider']
      user.name = data['name']
      user.email = data['email']
      user.created_at = data['created_at']
      user.password = 'temporary'
      user.password_confirmation = 'temporary'
      user.preferences = begin
        JSON.parse(data['settings'])
      rescue
        {}
      end
      user.link_id = data['link_id']
      user.save!

      user.update_columns(password: data['password'])

      puts "\tUser #{user.id} imported successfully."
    end

    # Account data:
    #
    # id label balance currency created_at user_id
    def import_account(data)
      puts "Importing account #{data['label']} for user #{data['user_id']}"

      user = User.find(data['user_id'].to_i)
      account = Account.new
      account.id = data['id']
      account.label = data['label']
      account.balance = 0
      account.currency = data['currency']
      account.created_at = data['created_at']
      account.user = user
      account.save!

      puts "\tAccount: #{account.id} imported."
    end

    # Category data:
    #
    #   id, name, icon, user_id
    def import_category(data)
      puts "Importing category #{data['name']} for user #{data['user_id']}"

      user = User.find(data['user_id'].to_i)
      category = Category.new
      category.id = data['id']
      category.name = data['name']
      category.icon = data['icon']
      category.user = user
      category.save!

      puts "\tCategory: #{category.id} imported successfully."
    end

    # PM data:
    #
    #   id name default color user_id
    def import_payment_method(data)
      puts "Importing payment method #{data['name']} for user #{data['user_id']}"
      user = User.find(data['user_id'].to_i)

      resource = PaymentMethod.new
      resource.id = data['id']
      resource.name = data['name']
      resource.default = !!data['default']
      resource.color = data['color']
      resource.user = user
      resource.save!

      puts "\tPayment Method: #{resource.id} imported successfully."
    end

    # Transaction data:
    #
    # id amount currency currency_rate note type occured_on created_at
    # account_id payment_method_id
    #
    # flow_type frequency recurs_on last_commit active recurring_id every
    # weekly_days monthly_days yearly_months yearly_day
    def import_recurring(data)
      puts "Importing recurring #{data['id']} for account #{data['account_id']}"
      account = Account.find(data['account_id'])

      resource = Recurring.new
      resource.id = data['id']
      resource.amount = data['amount']
      resource.currency = data['currency']
      resource.name = data['note']
      resource.created_at = data['created_at']
      resource.committed_at = data['last_commit']
      resource.flow_type = data['flow_type'].to_sym
      resource.frequency = data['frequency'].to_sym
      resource.active = !!data['active']
      resource.every = data['every']
      resource.weekly_days = data['weekly_days']
      resource.monthly_days = data['monthly_days']
      resource.yearly_months = data['yearly_months']
      resource.yearly_day = data['yearly_day']

      resource.payment_method = begin
        PaymentMethod.find(data['payment_method_id'])
      rescue
        puts "[WARN]\tUnable to find payment method #{data['payment_method_id']}"
        nil
      end

      resource.account = account
      resource.save!

      puts "\tRecurring: #{resource.id} imported successfully."
    end

    # Transaction data:
    #
    # id amount currency currency_rate note type occured_on created_at
    # account_id payment_method_id
    #
    # flow_type frequency recurs_on last_commit active recurring_id every
    # weekly_days monthly_days yearly_months yearly_day
    def import_transaction(data)
      puts "Importing transaction #{data['id']} for account #{data['account_id']}"
      account = Account.find(data['account_id'])

      resource = data['type'] == 'Deposit' ? Income.new : Expense.new
      resource.id = data['id']
      resource.amount = data['amount']
      resource.currency = data['currency']
      resource.currency_rate = data['currency_rate']
      resource.note = data['note']
      resource.occurred_on = data['occured_on']
      resource.created_at = data['created_at']

      resource.payment_method = begin
        PaymentMethod.find(data['payment_method_id'])
      rescue
        puts "[WARN]\tUnable to find payment method #{data['payment_method_id']}"
        nil
      end

      if data['recurring_id']
        resource.recurring = begin
          Recurring.find(data['recurring_id'])
        rescue
          puts "[WARN]\tUnable to find recurring #{data['recurring_id']}"
          nil
        end
      end

      resource.account = account
      resource.save!

      puts "\tTransaction: #{resource.id} imported successfully."
    end

    def import_category_transaction(data)
      transaction = begin
        Transaction.find_by_id(data['transaction_id']) ||
        Recurring.find_by_id(data['transaction_id'])
      end

      category = Category.find_by_id(data['category_id'])

      if category && transaction
        transaction.categories << category
        transaction.save!
      elsif !transaction
        puts "[WARN] Unable to find transaction #{data['transaction_id']} for category #{data['category_id']}"
      elsif !category
        puts "[WARN] Unable to find category #{data['category_id']} for transaction #{data['transaction_id']}"
      end
    end

    unless args[:path]
      puts 'Must provide a path to the JSON dump, e.g: ' +
        '`bundle exec rake pibi:import_from_legacy[path/to/dump.json]`'
      next
    end

    dump = JSON.parse(File.read(args[:path]))

    # Users
    ActiveRecord::Base.transaction do
      dump['users'] ||= []
      dump['users'].each do |user|
        next if blacklisted?(:users, user['id'])

        import_user(user)
      end
    end

    # Accounts
    ActiveRecord::Base.transaction do
      dump['accounts'] ||= []
      dump['accounts'].each do |account|
        next if blacklisted?(:accounts, account['id'])

        guard account do
          import_account(account)
        end
      end
    end

    # Categories
    ActiveRecord::Base.transaction do
      dump['categories'] ||= []
      dump['categories'].each do |resource|
        next if blacklisted?(:categories, resource['id'])

        guard resource do
          import_category(resource)
        end
      end
    end

    # Payment Methods
    ActiveRecord::Base.transaction do
      dump['payment_methods'] ||= []
      dump['payment_methods'].each do |resource|
        next if blacklisted?(:payment_methods, resource['id'])

        guard resource do
          import_payment_method(resource)
        end
      end
    end

    # Recurrings
    ActiveRecord::Base.transaction do
      dump['recurrings'] ||= []
      dump['recurrings'].each do |resource|
        next if blacklisted?(:recurrings, resource['id'])

        guard resource do
          fix_currency(resource)
          import_recurring(resource)
        end
      end
    end

    # Transactions
    ActiveRecord::Base.transaction do
      dump['transactions'] ||= []
      dump['transactions'].each do |resource|
        next if blacklisted?(:transactions, resource['id'])

        guard resource do
          fix_currency(resource)
          import_transaction(resource)
        end
      end
    end

    # CategoryTransactions
    ActiveRecord::Base.transaction do
      dump['category_transactions'] ||= []
      dump['category_transactions'].each do |resource|
        guard resource do
          import_category_transaction(resource)
        end
      end
    end

    puts "Number of failures: #{@failures.length}"
    puts "Failures:"
    puts @failures.to_json
  end

  task :import_from_legacy_fragments, [:path, :blacklist_path] => [:environment] do |t, args|
    unless args[:path]
      puts 'Must provide a path to the JSON fragment dump directory, e.g: ' +
        '`bundle exec rake pibi:import_from_legacy_fragments[path/to/dump_fragments/]`'
      next
    end

    cursor = 0
    cursor_path = Rails.root.join('tmp', 'legacy_fragment_importer.txt')

    if File.exists?(cursor_path)
      cursor = File.read(cursor_path).to_i
      puts "Resuming work from earlier import, starting at #{cursor}."
      puts "To re-run from scratch, delete the file at #{cursor_path} and run" +
        " this task again."
    end

    filenames = (Dir.entries(args[:path]) - ['.','..'] ).sort
    filenames.each_with_index do |filename, i|
      next if i < cursor

      filepath = "#{args[:path]}/#{filename}"
      puts "Importing #{filepath}"

      begin
        Rake::Task["pibi:import_from_legacy"].reenable
        Rake::Task["pibi:import_from_legacy"].invoke(filepath, args[:blacklist_path])
      rescue Exception => e
        puts "Import failed: #{e.message}"
        raise e unless ENV['FORCE']
      end

      cursor += 1
      File.write(cursor_path, cursor.to_s)
    end

    puts "Importing done. Make sure you adjust the SEQUENCES by running rake db:adjust_sequences"

    FileUtils.rm(cursor_path)
  end
end
