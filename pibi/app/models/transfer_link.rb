class TransferLink < ActiveRecord::Base
  belongs_to :source, class_name: 'Transaction'
  belongs_to :target, class_name: 'Transaction'

  def transactions
    Transaction.where(id: [ source_id, target_id ])
  end
end
