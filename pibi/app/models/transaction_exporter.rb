require 'csv'

class TransactionExporter
  def to_csv(scope)
    fields = %w[ id type amount currency note occurred_on account payment_method categories ]

    CSV.generate do |csv|
      csv << fields

      scope.each do |transaction|
        row = []
        row << transaction.id
        row << transaction.type
        row << transaction.amount
        row << transaction.currency
        row << transaction.note
        row << begin
          Time.zone.parse(transaction.raw_occurred_on || '') ||
          transaction.occurred_on ||
          transaction.created_at
        end.iso8601
        row << transaction.account.label
        row << transaction.payment_method.try(:name)
        row << transaction.categories.map do |category|
          category.name.gsub(',', '_')
        end.join(', ')

        csv << row
      end
    end
  end
end