class PrivacyPolicy < ActiveRecord::Base
  belongs_to :user

  serialize :metric_blacklist
  before_save :set_defaults

  EXPORTABLE_ATTRIBUTES = [
    :wants_newsletter,

    # are we allowed to track analytics metrics for this user?
    :trackable,

    # can we track analytics on mobile platforms?
    :mobile_trackable,

    # are specific analytics metrics disallowed?
    :metric_blacklist
  ]

  METRICS = [
    "Transactions: Create",
    "Transactions: Update",
    "Transactions: Remove",
    "Transactions: CSV",
    "Transactions: Filter",
    "Accounts: Create",
    "Accounts: Update",
    "Accounts: Remove",
    "Categories: Create",
    "Categories: Update",
    "Categories: Remove",
    "Payment Methods: Create",
    "Payment Methods: Update",
    "Payment Methods: Remove",
    "Password Reset",
    "Change Resetted Password",
    "Change Theme",
    "Currencies: Add To List",
    "Currencies: Remove From List",
    "Users: Signup",
    "Change Password",
    "Login",
    "Recurrings: Create",
    "Recurrings: Update",
    "Recurrings: Activate",
    "Recurrings: Deactivate",
    "Recurrings: Remove",
    "Attachments: Upload",
    "Attachments: Remove",
    "Attachments: Limit Exceeded"
  ].freeze

  def set_defaults
    self.metric_blacklist = [] if self.metric_blacklist.blank?
    self.wants_newsletter = true if self.wants_newsletter.nil?
    self.trackable = true if self.trackable.nil?
    self.mobile_trackable = true if self.mobile_trackable.nil?
  end
end
