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

class TransactionService < Service
  def create(account, params)
    params.delete(:id)

    if params[:type]
      params[:type] = params[:type].to_s.capitalize.to_s

      unless [ 'Income', 'Expense' ].include?(params[:type])
        return reject_with 'Unrecognized transaction type.'
      end
    end

    # need to assign splits separately after the amount is set so we can
    # validate it...
    splits = params.delete(:splits)

    transaction = account.transactions.build(params)
    transaction.splits = splits
    transaction.save

    unless transaction.valid?
      return reject_with transaction.errors
    end

    accept_with transaction
  end

  def update(transaction, params)
    params.delete(:type)
    params.delete(:id)

    Transaction.transaction do
      transaction.update!(params)

      if transaction.transfer?
        transaction.transfer_spouse.update!(params)
      end
    end

    accept_with transaction
  rescue ActiveRecord::RecordInvalid => e
    reject_with(e.record.errors)
  end

  def destroy(transaction)
    if transaction.inbound_transfer.present?
      transaction = transaction.inbound_transfer.source
    end

    unless transaction.destroy
      return reject_with transaction.errors
    end

    accept_with nil
  end

  def transfer(source_account, target_account, params)
    params.delete(:type)
    params.delete(:id)
    params[:is_transfer] = true

    transfer = nil

    transfer = Transaction.transaction do
      source_transaction = source_account.expenses.create!(params)
      target_transaction = target_account.incomes.create!({
        is_transfer: true,
        amount: source_transaction.amount,
        note: source_transaction.note,
        currency: source_transaction.currency,
        currency_rate: source_transaction.currency_rate,
        occurred_on: source_transaction.occurred_on,
        payment_method_id: source_transaction.payment_method_id,
        category_ids: source_transaction.category_ids,
        splits: source_transaction.splits,
        committed: false
      })

      TransferLink.transaction do
        source_transaction.create_outbound_transfer({
          target: target_transaction
        })
      end
    end

    accept_with transfer
  rescue ActiveRecord::RecordInvalid => e
    reject_with(e.record.errors)
  end
end
