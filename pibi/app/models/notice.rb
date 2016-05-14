class Notice < ActiveRecord::Base
  belongs_to :user

  def accept!
    case self.cause
    when 'email_verification'
      self.user.update({ email_verified: true })
    end

    self.update({ accepted: true })
  end
end
