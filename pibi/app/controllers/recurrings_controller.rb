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
# @API Recurrings
#
# An interface for managing an account's recurrings.
#
# Recurring transactions are transactions that happen regularly on a certain
# day of the week, month, or year. Bills, salaries, and loans are all
# recurring transactions. To save you the trouble from manually entering these
# transactions every time they occur, Pibi can automate the process for you via
# Recurrings.
#
# Recurrings can be scheduled to occur on a daily, weekly, monthly, or yearly
# basis which is referred to as their *frequency*.
#
# @object Recurring
#  {
#    // The unique id of the recurring.
#    "id": 1,
#
#    // The account this recurring belongs to
#    "account_id": 1,
#
#    // A unique name or label for the recurring.
#    "name": "Phone Bill",
#
#    // The amount of money represented by the recurring transaction
#    "amount": 10.0,
#
#    // The currency in which the transaction recurs
#    "currency": "USD",
#
#    // Whether the recurring will spawn an income or an expense.
#    //
#    // Accepted values: [ 'positive', 'negative' ]
#    "flow_type": "negative",
#
#    // How often the transaction recurs.
#    //
#    // Accepted values: [ 'daily', 'weekly', 'monthly', 'yearly' ]
#    "frequency": "monthly",
#
#    // The interval in which the frequency is applicable. For example:
#    //
#    // - for weekly recurrings, if this is set to 2, it means "every two other weeks"
#    // - for monthly recurrings, if this is set to 4, it means "every four months"
#    // - for yearly recurrings, if this is set to 1, it means "every year"
#    // - for daily recurrings, if this is set to 7, it means "every 7 days" which
#    //   is the same as setting it to weekly and specifying and "every" of 1
#    "every": 1,
#
#    // Inactive recurrings will not be committed.
#    "active": true,
#
#    // The payment method the transaction occurs in
#    "payment_method_id": null,
#
#    // Days of the week the weekly transaction recurs in. So this would be
#    // every Sunday and Tuesday of every week.
#    //
#    // Accepted values: [
#    //   'sunday', 'monday', 'tuesday',
#    //   'wednesday', 'thursday', 'friday',
#    //   'saturday'
#    // ]
#    "weekly_days": [ "sunday", "tuesday" ],
#
#    // Days of the month the monthly transaction recurs in, so this would be
#    // the 3rd and 19th days of every month.
#    //
#    // Accepted values: [ -1, 1..31 ]
#    "monthly_days": [ 3, 19 ],
#
#    // Months of the year the transaction recurs in, so this would be
#    // February and December of every year.
#    //
#    // Accepted values: [ 1..12 ]
#    "yearly_months": [ 2, 12 ],
#
#    // The day of each month the yearly transaction recurs in, so this would
#    // be the first of February and December.
#    //
#    // Accepted values: [ -1, 1..31 ]
#    "yearly_day": 1
#  }
class RecurringsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  Frequencies = %w[ daily monthly weekly yearly ]
  FlowTypes = %w[ positive negative ]

  before_filter :require_user
  before_filter :require_account, except: [ :upcoming ]
  before_filter :require_recurring, except: [ :index, :create, :upcoming ]
  before_filter :prepare_service, except: [ :index, :show, :upcoming ]

  # @API Reading recurrings
  #
  # Get a list of recurrings and optionally filter the collection.
  #
  # @argument [String] flow_type (optional)
  #   Filter the recurrings by their flow type.
  #   Accepted values: [ 'positive', 'negative' ]
  #
  # @argument [String] frequency (optional)
  #   Filter by the frequency of the recurring.
  #   Accepted values: [ 'daily', 'weekly', 'monthly', 'yearly' ]
  #
  # @argument [Array] frequencies (optional)
  #   Filter by a group of frequencies.
  #   See #frequency for the accepted values.
  #
  # @argument [Boolean] active (optional)
  #   Filter by the active status of the recurring. If unspecified, both active
  #   and inactive recurrings will be fetched.
  #
  # @example_request
  #  // Active, monthly recurrings:
  #  {
  #    "frequency": "monthly",
  #    "active": true
  #  }
  #
  # @example_request
  #  // Inactive daily and weekly recurrings
  #  {
  #    "frequencies": [ "daily", "weekly" ],
  #    "active": false
  #  }
  #
  # @example_request
  #  // Negative recurrings, aka bills:
  #  {
  #    "flow_type": "negative"
  #  }
  #
  # @returns
  #   {
  #     "recurrings": [ Recurring ]
  #   }
  def index
    parameter :flow_type, type: :string, in: %w[ positive negative ]
    parameter :frequency, type: :string, in: %w[ daily monthly weekly yearly ]
    parameter :frequencies, type: :array, in: %w[ daily monthly weekly yearly ]
    parameter :active, type: :boolean, coerce: true

    query = {}

    if api.parameters.has_key?(:active)
      query[:active] = api.get(:active)
    end

    recurrings = @account.recurrings.where(query)

    if flow_type = api.get(:flow_type)
      recurrings = recurrings.with_flow_type(flow_type.to_sym)
    end

    frequencies = api.get(:frequency) || api.get(:frequencies)

    if frequencies.present?
      recurrings = recurrings.with_frequency(*[ frequencies ].flatten)
    end

    expose recurrings
  end

  # @API Retrieving upcoming recurrings
  #
  # Get a list of *active* recurrings that are due within a time frame.
  #
  # @argument [DateTime] from (optional)
  #   Only count recurrings that are due after this date. If left unspecified,
  #   all recurrings that are due by the end date (specified in `to`) will be
  #   returned.
  #
  # @argument [DateTime] to (optional)
  #   Only count recurrings that are due before this date.
  #
  # @argument [String] flow_type (optional)
  #   Filter the recurrings by their flow type.
  #   Accepted values: [ 'positive', 'negative' ]
  #
  # @argument [Array] frequencies (optional)
  #   Filter by a group of frequencies.
  #   See #frequency for the accepted values.
  #
  # @example_request Recurrings that are due this week.
  #  {
  #    "from": "2014-02-19T00:00:00Z",
  #    "to": "2014-02-26T00:00:00Z"
  #  }
  #
  # @returns
  #   {
  #     "recurrings": [ Recurring ]
  #   }
  def upcoming
    accepts :account_ids
    parameter :from, type: :date
    parameter :to, type: :date, default: 1.week.from_now(Time.now.end_of_day)
    parameter :frequencies, type: :array, in: %w[ daily monthly weekly yearly ]
    parameter :flow_type, type: :string, in: %w[ positive negative ]

    frequencies = api.get(:frequency) || api.get(:frequencies)
    account_ids = api.consume :account_ids do |account_ids|
      account_ids.compact.uniq
    end

    if api.get(:from)
      if api.get(:to) < api.get(:from)
        halt! 400, 'That is not a valid time range.'
      end
    end

    if account_ids.blank?
      account_ids = current_user.accounts.pluck(:id).map(&:to_s)
    else
      account_ids.any? do |id|
        account = current_user.accounts.find_by_id(id.to_s)

        if account.nil? || can?(:read, account.recurrings)
          halt! 403, "You do not have access to account##{id}."
        end
      end
    end

    recurrings = Recurring.where({
      account_id: account_ids,
      active: true
    })

    if frequencies.present?
      recurrings = recurrings.with_frequency(frequencies)
    end

    if flow_type = api.get(:flow_type)
      recurrings = recurrings.with_flow_type(flow_type.to_sym)
    end

    period = if api.get(:from)
      api.get(:from)..api.get(:to)
    else
      api.get(:to)
    end

    recurrings = recurrings.select do |recurring|
      if period.is_a?(Range)
        period.cover?(recurring.next_billing_date)
      else
        recurring.next_billing_date <= period
      end
    end

    expose recurrings, paginate: false
  end

  # @API Creating recurrings
  #
  # Create a new account recurring.
  #
  # @argument [String] flow_type
  #  ...
  #
  # @argument [String] name
  #   A unique label for this recurring.
  #
  # @argument [Decimal] amount
  #   The amount of money the recurring represents.
  #
  # @argument [String] frequency
  #   ...
  #
  # @argument [String] currency (optional)
  #   ISO code of the currency in which the recurring was made.
  #   Defaults to the account's currency.
  #
  # @argument [Boolean] active (optional)
  #   ...
  # @argument [Integer] every (optional)
  #   ...
  #
  # @argument [Array<String>] weekly_days (optional) ...
  # @argument [Array<Integer>] monthly_days (optional) ...
  # @argument [Array<Integer>] yearly_months (optional) ...
  # @argument [Integer] yearly_day (optional) ...
  #
  # @argument [Integer] payment_method_id (optional)
  #   Associate the recurring with a payment method.
  #
  # @argument [Array<Integer>] category_ids (optional)
  #   Associate the recurring with a number of categories.
  #
  # @returns
  #   {
  #     "recurrings": [ Recurring ]
  #   }
  def create
    parameter_group true

    with_service @service.create(@account, api.parameters) do |recurring|
      playback :create, recurring
      expose recurring
    end
  end

  def show
    expose @recurring
  end

  # @API Updating recurrings
  #
  #
  def update
    parameter_group false

    with_service @service.update(@recurring, api.parameters) do |recurring|
      playback :update, recurring
      expose recurring
    end
  end

  def destroy
    with_service @service.destroy(@recurring) do |rc|
      playback :delete, @recurring
      no_content!
    end
  end

  private

  def prepare_service
    @service = RecurringService.new
  end

  def require_account
    with :account
  end

  def require_recurring
    with :account, :recurring
  end

  def parameter_group(strict=true)
    parameter :name, type: :string, required: strict
    parameter :flow_type, type: :string, in: FlowTypes, required: strict
    parameter :amount, type: :float, required: strict
    parameter :currency, type: :string
    parameter :active, type: :boolean
    parameter :frequency, type: :string, in: Frequencies, required: strict
    parameter :every, type: :integer, default: 1
    parameter :weekly_days, type: :array
    parameter :monthly_days, type: :array
    parameter :yearly_months, type: :array
    parameter :yearly_day, type: :integer, allow_nil: true
    parameter :payment_method_id, allow_nil: true
    parameter :category_ids, type: :array
  end
end