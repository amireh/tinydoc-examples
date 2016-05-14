# Pibi API - The official JSON API for Pibi, the personal financing software.
# Copyright (C) 2014 Ahmad Amireh <ahmad@algollabs.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##
# @API Transactions
#
# An interface for managing an account's transactions.
#
# @object Transaction
#  {
#    // The unique id of the transaction.
#    "id": 1
#  }
#
# @object Split
#  {
#    // A UUID for this split. This may be generated on the client-side.
#    "id": "d6704ca0-2ed7-0132-6299-1c6f65c9d202",
#
#    // The amount this chunk represents from the total amount.
#    "amount": 10.0,
#
#    // A very short note to explain what this chunk was for.
#    "memo": "Apple juice"
#  }
class TransactionsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_account, only: [ :index, :create, :show, :update, :destroy ]
  before_filter :require_transaction, only: [ :show, :update, :destroy ]
  before_filter :prepare_service, only: [ :create, :update, :destroy, :transfer ]

  # @API Retrieving account transactions
  #
  # Get a list of transactions and optionally filter the collection.
  #
  # @argument [String] type (optional)
  #   Filter the transactions by their type.
  #   Accepted values: [ 'expense', 'income' ]
  #
  # @argument [String] from (optional)
  #   Specifies the beginning of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _beginning_ of the
  #   specified day, eg: `00:00:00`.
  #
  # @argument [String] to (optional)
  #   Specifies the end of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _end_ of the
  #   specified day, e.g: `23:59:59`.
  #
  # @example_request
  #  {
  #    "from": "2014-02-18T00:00:00Z",
  #    "to": "2014-02-24T00:00:00Z",
  #    "type": "expense"
  #  }
  #
  # @returns
  #   {
  #     "transactions": [ Transaction ]
  #   }
  def index
    parameter :from, type: :date, default: Time.now.beginning_of_month
    parameter :to, type: :date, default: Time.now.end_of_month
    parameter :type, type: :string, in: [ 'expense', 'income' ]

    api.transform :from do |date| date.beginning_of_day end
    api.transform :to do |date| date.end_of_day end

    transactions = @account.transactions.
      occurred_in(api.get(:from), api.get(:to)).
      includes(:categories, :attachments)

    if type = api.get(:type)
      transactions = transactions.where(:type => type.capitalize)
    end

    expose transactions, each_serializer: TransactionSerializer
  end

  # @API Retrieving transactions across multiple accounts
  #
  # Get a list of transactions that have been tracked in any number of accounts,
  # and optionally filter the collection.
  #
  # @argument [Array<String>] account_ids (optional)
  #   IDs of the accounts. If left blank, all accounts will be used.
  #
  # @argument [String] type (optional)
  #   Filter the transactions by their type.
  #   Accepted values: [ 'expense', 'income' ]
  #
  # @argument [String] from (optional)
  #   Specifies the beginning of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _beginning_ of the
  #   specified day, eg: `00:00:00`.
  #
  # @argument [String] to (optional)
  #   Specifies the end of the date-range.
  #   Value can be a JSON timestamp, or a string following the format "MM/DD/YYYY".
  #
  #   *Note*:
  #   The value will be automatically mapped to mark the _end_ of the
  #   specified day, e.g: `23:59:59`.
  #
  # @example_request
  #  {
  #    "from": "2014-02-18T00:00:00Z",
  #    "to": "2014-02-24T00:00:00Z",
  #    "type": "expense"
  #  }
  #
  # @returns
  #   {
  #     "transactions": [ Transaction ]
  #   }
  def mega_index
    accepts :account_ids
    parameter :from, type: :date, default: Time.now.beginning_of_month
    parameter :to, type: :date, default: Time.now.end_of_month
    parameter :type, type: :string, in: [ 'expense', 'income' ]

    api.transform :from do |date| date.beginning_of_day end
    api.transform :to do |date| date.end_of_day end

    account_ids = api.consume :account_ids do |account_ids|
      account_ids.compact.uniq
    end

    if account_ids.blank?
      account_ids = current_user.accounts.pluck(:id).map(&:to_s)
    else
      account_ids.any? do |id|
        account = current_user.accounts.find_by_id(id.to_s)

        if account.nil? || can?(:read, account.transactions)
          halt! 403, "You do not have access to account##{id}."
        end
      end
    end

    transactions = Transaction
      .where(account_id: account_ids)
      .occurred_in(api.get(:from), api.get(:to))

    if type = api.get(:type)
      transactions = transactions.where(type: type.capitalize)
    end

    expose transactions, each_serializer: TransactionSerializer
  end

  # @API Creating transactions
  #
  # Creating a transaction can be as simple as typing in the amount; that's all
  # that's actually necessary for Pibi to save it for you. However, we recommend
  # that you make use of the rest of the features provided by the transaction
  # interface to maximize your Pibi experience. Here are a few guidelines:
  #
  # * Use the `note` to remind you of what that transaction was about, or where
  #   it happened
  # * Use one or more [categories](categories.html), to **group and classify** the
  #   transaction - e.g: whenever you buy some groceries, tag them with the
  #   Groceries category, and then write a note to remind you of what kind of
  #   groceries those were, like 'Apples' or 'Juice'
  # * Use a [payment method](payment_methods.html) to remind yourself of how you
  #   made that transaction. Was it in cash, or perhaps by writing a cheque?
  #
  # @argument [String] type
  #   Type of the transaction to create.
  #   Accepted values: [ 'expense', 'income' ]
  #
  # @argument [Decimal] amount
  #   The amount of money the transaction represents.
  #
  # @argument [DateTime] occurred_on (optional)
  #   The time at which the transaction occurred. Defaults to the current time.
  #
  # @argument [String] currency (optional)
  #   ISO code of the currency in which the transaction was made.
  #   Defaults to the account's currency.
  #
  # @argument [String] note (optional)
  #   A note to remind you of this transaction.
  #
  # @argument [Integer] payment_method_id (optional)
  #   Associate the transaction with a payment method.
  #
  # @argument [Array<Integer>] category_ids (optional)
  #   Associate the transaction with a number of categories.
  #
  # @argument [Array<Split>] splits (optional)
  #   Drill-down of the amount.
  #
  # @returns
  #   {
  #     "transactions": [ Transaction ]
  #   }
  def create
    parameter :type, type: :string, in: [ 'expense', 'income' ], required: true
    parameter :amount, type: :float, required: true
    parameter :occurred_on, type: :date
    parameter :splits, type: :array
    accepts :currency, :note, :payment_method_id, :category_ids

    parameters = api.parameters.merge({
      raw_occurred_on: params[:occurred_on_original]
    })

    with_service @service.create(@account, parameters) do |transaction|
      playback :create, transaction
      expose transaction, serializer: TransactionSerializer
    end
  end

  # @API Transfering money
  #
  # Creating a transfer is done by specifying a source account, from which the
  # money will be withdrawn, and a target account, in which the money will be
  # deposited.
  #
  # Once a transfer is made, two transactions will appear, one in each account.
  # These transactions will always be linked together; updating one will update
  # the other. Likewise, destroying any end of the transfer will abort the
  # transfer completely (both transactions will be wiped.)
  #
  # The output of this endpoint is a list of the two transactions.
  #
  # @argument [String] source_account_id
  #   ID of the source account.
  #
  # @argument [String] target_account_id
  #   ID of the source account.
  #
  # @argument [Decimal] amount
  #   The amount of money the transaction represents.
  #
  # @argument [DateTime] occurred_on (optional)
  #   The time at which the transaction occurred. Defaults to the current time.
  #
  # @argument [String] currency (optional)
  #   ISO code of the currency in which the transaction was made.
  #   Defaults to the account's currency.
  #
  # @argument [String] note (optional)
  #   A note to remind you of this transaction.
  #
  # @argument [Integer] payment_method_id (optional)
  #   Associate the transaction with a payment method.
  #
  # @argument [Array<Integer>] category_ids (optional)
  #   Associate the transaction with a number of categories.
  #
  # @argument [Array<Split>] splits (optional)
  #   Drill-down of the amount.
  #
  # @returns
  #   [ Transaction, Transaction ]
  def transfer
    parameter :source_account_id, required: true
    parameter :target_account_id, required: true
    parameter :amount, type: :float, required: true
    parameter :occurred_on, type: :date
    parameter :splits, type: :array
    accepts :currency, :note, :payment_method_id, :category_ids

    source_account, target_account = [ :source, :target ].map do |type|
      api.consume(:"#{type}_account_id") do |id|
        account = current_user.accounts.where(id: id).first

        if account.nil?
          halt! 404, "[TX:TRANSFER_INVALID_ACCOUNT] account does not exist"
        end

        unless can?(:update, account)
          halt! 403, "[TX:TRANSFER_ACCOUNT_INACCESSIBLE] account is not accessible"
        end

        account
      end
    end

    parameters = api.parameters.merge({
      raw_occurred_on: params[:occurred_on_original]
    })

    with_service @service.transfer(source_account, target_account, parameters) do |transfer_link|
      transfer_link.transactions.each do |tx|
        playback :create, tx
      end

      expose transfer_link.transactions, each_serializer: TransactionSerializer
    end
  end

  def show
    expose @transaction, serializer: TransactionSerializer
  end

  # @API Updating transactions
  #
  #
  def update
    parameter :amount, type: :float
    parameter :occurred_on, type: :date
    parameter :splits, type: :array
    accepts :currency, :note, :payment_method_id, :category_ids

    parameters = api.parameters
    parameters.merge!({
      raw_occurred_on: params[:occurred_on_original]
    }) if params[:occurred_on_original].present?

    with_service @service.update(@transaction, parameters) do |transaction|
      playback :update, transaction
      playback :update, transaction.transfer_spouse if transaction.transfer?

      expose transaction, serializer: TransactionSerializer
    end
  end

  def destroy
    with_service @service.destroy(@transaction) do |rc|
      playback :delete, @transaction
      playback :delete, @transaction.transfer_spouse if @transaction.transfer?

      no_content!
    end
  end

  private

  def prepare_service
    @service = TransactionService.new
  end

  def require_account
    with :account
  end

  def require_transaction
    with :account, :transaction
  end
end