require 'money'
require 'money/bank/open_exchange_rates_bank'

namespace :pibi do
  namespace :currencies do
    desc "updates the currency exchange rates"
    task :update => :environment do
      puts "Retrieving latest exchange rates from Open Exchange Rates..."
      settings = Rails.application.config.open_exchange_rates

      bank = Money.default_bank = Money::Bank::OpenExchangeRatesBank.new
      bank.cache = File.join(Rails.root, 'tmp', 'oer_currencies.json')
      bank.app_id = settings[:app_id]
      bank.update_rates

      list = bank.doc["rates"]

      puts "#{list.length} currencies retrieved, updating exchange rates..."

      # Make sure USD is there
      Currency.where({ name: 'USD' }).first_or_create do |currency|
        currency.rate = 1.0
      end

      list.each_pair do |iso_code, rate|
        next if !rate

        # look up the symbol, if possible
        symbol = begin
          Money::Currency.find(iso_code).symbol
        rescue
          nil
        end || iso_code

        currency = Currency.where({ name: iso_code }).first_or_create do |currency|
          currency.rate = 1
        end

        currency.update_columns({ rate: rate, symbol: symbol })

        Rails.cache.fetch(Currency.cache_key(iso_code), force: true) do
          currency
        end
      end

      puts "Currency exchange rates have updated."
      puts "#{Currency.count} currencies are now available."
    end

    desc 'the number of currencies with invalid rate'
    task :invalid => :environment do
      puts Currency.all({ rate: 0 }).map(&:name)
    end

    desc 'remove invalid currencies'
    task :remove_invalid => :environment do
      Currency.where({ rate: 0 }).each do |c|
        transies = Transaction.all({ currency: c.name })
        transies.each do |tx|
          tx.update({
            currency: 'USD',
            currency_rate: 1
          })
        end

        puts "Adjusted #{transies.length} transactions to use USD instead of #{c.name}"
      end

      Currency.where({ rate: 0 }).destroy
    end
  end
end
