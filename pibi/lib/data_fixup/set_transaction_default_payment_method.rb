class DataFixup::SetTransactionDefaultPaymentMethod
  def run
    User.all.each do |user|
      payment_method_id = user.default_payment_method.try(:id)

      next unless payment_method_id.present?

      user.accounts.each do |account|
        account.transactions.where(payment_method_id: nil).update_all(payment_method_id: payment_method_id)
      end
    end
  end
end