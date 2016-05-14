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

class User < ActiveRecord::Base
  include Journallable

  attr_accessor :current_password
  attr_accessor :password_confirmation
  attr_accessor :token

  cattr_accessor :default_payment_methods
  cattr_accessor :default_categories

  MinPasswordLength = 7

  has_many :links, class_name: 'User', :foreign_key => :link_id, dependent: :destroy
  belongs_to :link, class_name: 'User', :foreign_key => :link_id

  has_many :access_tokens, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :journals, dependent: :destroy
  has_many :notices, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :progresses, dependent: :destroy
  has_many :data_exports, {
    class_name: 'Attachment',
    as: :attachable,
    dependent: :destroy
  }

  has_one :privacy_policy, dependent: :destroy

  before_save :encrypt_password
  before_save :accept_preferences, if: :preferences_changed?
  after_save :create_privacy_policy

  serialize :preferences

  validates_presence_of :email,
    message: '[USR:EMAIL_MISSING] We need your email address.'

  validates_presence_of :name,
    message: '[USR:NAME_MISSING] We need your name.'

  validates_presence_of :password,
    message: '[USR:PASSWORD_MISSING] You must provide a password.'

  validates_presence_of :password_confirmation,
    if: :password_changed?,
    message: '[USR:PASSWORD_CONFIRMATION_MISSING] You must confirm the password.'

  validates_confirmation_of :password,
    message: '[USR:PASSWORD_MISMATCH] Passwords must match.'

  validates_length_of :password, :minimum => MinPasswordLength,
    message: "[USR:PASSWORD_TOO_SHORT] " +
    "Password is too short, it must be at least #{MinPasswordLength} characters long."

  validates_uniqueness_of :email, :scope => :provider,
    message: "[USR:EMAIL_UNAVAILABLE] " +
    "There's already an account registered to this email address."

  validates :email, with: :validate_email_address, if: :email_changed?
  validates :password, with: :validate_password, if: :password_changed?

  def self.encrypt(passcode)
    Digest::SHA1.hexdigest(passcode || "")
  end

  def validate_email_address
    unless self.email.include?('@')
      errors.add :email, "[USR:EMAIL_INVALID] Doesn't look like an email address to me..."
    end
  end

  # Link this user along with its current links to a new master user.
  def link_to(master)
    return true if master == self

    master.links << self

    self.link = master
    self.links.each { |linked_user| linked_user.link_to(master) }
    self.links = []

    self.save
  end

  # Whether this user has a link with another.
  #
  # @param [User|String] provider_or_user
  #   The target to test. If you pass a provider string (like "facebook"), then
  #   the current user's links will be tested for any account created from the
  #   specified provider.
  #
  # @example
  #   User.first.link_to(user_from_facebook)
  #   User.first.linked_to?('facebook') # => true
  #   User.first.linked_to?(user_from_facebook) # => true
  def linked_to?(provider_or_user)
    if provider_or_user.is_a?(User)
      user = provider_or_user

      return link == user || links.map(&:id).include?(user.id)
    end

    provider = provider_or_user

    return true if link && link.provider == provider
    return links.where({ provider: provider.to_s }).any?
  end

  def detach_from_master()
    if self.link
      self.link = nil
      self.save
    end
  end

  def preferences
    parse_preferences(read_attribute(:preferences))
  end

  def default_payment_method
    self.payment_methods.where({ default: true }).first
  end

  def default_account
    self.accounts.first
  end

  def generate_reset_password_token(commit=true)
    token = TokenGenerator.urlsafe_token

    update({ reset_password_token: token }) if commit

    token
  end

  def generate_email_verification_notice()
    self.notices.where({ cause: 'email_verification' }).destroy_all
    self.notices.create({
      cause: 'email_verification',
      token: TokenGenerator.urlsafe_token,
      accepted: false
    })
  end

  def first_name
    self.name.split(/\s/)[0]
  end

  protected

  def encrypt_password
    if password_changed?
      self.password = User.encrypt(password)
      self.password_confirmation = User.encrypt(password_confirmation)
    end
  end

  # Merge existing preferences with new ones.
  def accept_preferences
    old_preferences = parse_preferences self.preferences_was
    new_preferences = parse_preferences read_attribute(:preferences)

    self.preferences = old_preferences.deep_merge(new_preferences)
  end

  # Parse JSON preferences. No-op if preferences are already parsed.
  def parse_preferences(prefs)
    hsh = begin
      prefs.is_a?(Hash) ? prefs : JSON.parse(prefs)
    rescue
      {}
    end

    hsh.with_indifferent_access
  end

  def validate_password
    old_password = self.password_was

    return unless old_password.present?

    if token.present?
      unless token == self.reset_password_token
        errors.add :reset_password_token,
          '[USR_INVALID_RPT] Invalid reset password token.'
      end

      # discard the token
      self.reset_password_token = nil
    elsif User.encrypt(self.current_password) != old_password
      errors.add :current_password,
        '[USR_BAD_PASSWORD] The current password you entered is wrong.'
    end
  end
end
