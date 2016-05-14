module Transferable
  extend ActiveSupport::Concern

  included do |base|
    base.class_eval do
      has_one :outbound_transfer,
        class_name: 'TransferLink',
        foreign_key: 'source_id',
        dependent: :destroy

      has_one :inbound_transfer,
        class_name: 'TransferLink',
        foreign_key: 'target_id',
        dependent: :destroy

      before_destroy do
        if inbound_transfer.present?
          errors[:base] << "[TRANSFER_LOCKED] items at the target end of the transfer can not be removed directly"
          return false
        end

        outbound_transfer.target.destroy! if outbound_transfer.present?
      end
    end
  end

  def transfer?
    is_transfer
  end

  def transfer_spouse
    if outbound_transfer.present?
      outbound_transfer.target
    elsif inbound_transfer.present?
      inbound_transfer.source
    end
  end
end