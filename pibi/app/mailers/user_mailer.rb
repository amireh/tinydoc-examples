class UserMailer < ActionMailer::Base
  include Resque::Mailer
  add_template_helper(MailHelper)

  layout 'mail'
  before_action :attach_logo
  # after_action :fix_mixed_attachments

  def reset_password(user_id)
    @user = User.find(user_id)
    mail(to: @user.email, subject: 'Reset your Pibi password')
  end

  def verify_email(user_id)
    @user = User.find(user_id)
    @notice = @user.notices.where({ cause: 'email_verification' }).last
    mail(to: @user.email, subject: 'Verify your Pibi account')
  end

  def transaction_report(user_id)
    @user = User.find(user_id)
    @transactions = Transaction.where(account_id: @user.accounts.map(&:id)).occurred_in(Time.now.beginning_of_month, Time.now.end_of_month)

    mail(to: @user.email, subject: "#{Time.now.strftime('%M')} Activity")
  end

  private

  def attach_logo
    @image = File.read(Rails.public_path.to_s + '/images/pibi-icon-48.png')
    attachments.inline['pibi-icon-48.png'] = @image
  end

  def fix_mixed_attachments
    # do nothing if we have no actual attachments
    return if @_message.parts.select { |p| p.attachment? && !p.inline? }.none?

    mail = Mail.new

    related = Mail::Part.new
    related.content_type = @_message.content_type
    @_message.parts.select { |p| !p.attachment? || p.inline? }.each { |p| related.add_part(p) }
    mail.add_part related

    mail.header       = @_message.header.to_s
    mail.content_type = nil
    @_message.parts.select { |p| p.attachment? && !p.inline? }.each { |p| mail.add_part(p) }

    @_message = mail
    wrap_delivery_behavior!(delivery_method.to_sym)
  end
end