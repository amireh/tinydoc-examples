class MailPreview < MailView
  def reset_password
    UserMailer.reset_password(User.first.id)
  end

  def verify_email
    @user = User.first
    @user.generate_email_verification_notice

    UserMailer.verify_email(@user.id)
  end

  def transaction_report
    @user = User.first
    UserMailer.transaction_report(@user.id)
  end
end