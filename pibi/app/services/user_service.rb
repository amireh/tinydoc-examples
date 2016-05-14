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

class UserService < Service
  EMERGENCY_ACCOUNT_LABEL = 'Emergency Savings'
  EMERGENCY_BUDGET_NAME = 'Be prepared for emergencies. They do happen!'

  def self.journal_operations
    [ :update ]
  end

  # Create a new user
  def create(params)
    params.delete(:id)
    params = {
      uid: UUID.generate.to_s,
      provider: 'pibi'
    }.merge(params)

    user = User.create(params)

    unless user.valid?
      return reject_with user.errors
    end

    # create a default account
    user.accounts.create

    # create the Emergency Savings plan; account and budget
    create_emergency_savings_package(user)

    # create starter payment methods
    User.default_payment_methods.each do |entry|
      user.payment_methods.create(entry)
    end

    # create starter categories
    User.default_categories.each do |entry|
      user.categories.create({ name: entry, icon: entry.sanitize })
    end

    accept_with user
  end

  # Create, or find, a user given an OmniAuth auth hash.
  def find_or_create_from_oauth(provider, auth, current_user=nil)
    rc = Result.new
    master = nil
    slave = nil
    # user_info = {}
    user_info = oauth_to_user_hash(provider, auth)

    slave = User.find_by({ provider: provider, uid: auth.uid.to_s })
    new_user = slave.nil?

    logger.debug "Finding (or creating) a user from OAuth (#{provider})."
    logger.debug auth.to_hash.to_json

    # create the user if it's their first time
    if slave.nil?
      logger.debug("OAuth: registering new user.")

      slave = User.create(user_info)

      # There's an edge case that happens here where the provider decides to
      # change a UID of a user (like Facebook with their move from Graph API
      # v1.0 to v2.0).
      #
      # The email will be taken and it will map to the old UID, in which case
      # I believe the correct way to handle it is to re-map using the new UID,
      # hoping that email is the valid identifier to trust here.
      #
      # @since 31/05/2014
      if !slave.valid? && slave.errors.has_key?(:email)
        email_error = Array.wrap(slave.errors.get(:email)).join('')

        if email_error =~ /USR:EMAIL_UNAVAILABLE/
          logger.warn <<-Message
            It seems like the user's 3rd-party provider (#{provider}) has
            changed the UID for user #{user_info[:email]}, trying to amend...
          Message

          slave = User.find_by({ provider: provider, email: user_info[:email] })

          if slave.present?
            logger.info <<-Message
              Ok, I found one: #{slave.id}.
              UID has changed from #{auth.uid} to #{slave && slave.uid}
            Message

            slave.update!({ uid: auth.uid.to_s })
            return find_or_create_from_oauth(provider, auth)
          end
        else
          return rc.reject slave.errors
        end
      elsif !slave.valid?
        logger.warn "Unable to create user from auth has: #{slave.errors}, auth hash: #{auth.to_hash.to_json}"

        return rc.reject slave.errors
      end
    end

    # Create a Pibi user and use it as a master if the user isn't authenticated
    # (ie, isn't linking a 3rd-party account)
    if new_user && current_user.nil?
      logger.debug "\tAttempting to create a master user for the newly created OAuth one."
      master_creation = create(user_info.merge({ provider: 'pibi' }))

      # Can't create a master account? perhaps the email is already registered,
      # in this case we can do one of two things:
      #
      #   1. accept the 3rd-party account as a master but then the user will not
      #      be able to authenticate manually as that's exclusive to Pibi users
      #   2. reject the sign-up entirely
      #
      # For now, we will opt for #1
      if !master_creation.successful?
        logger.warn "Unable to create a master user for: #{user_info}, looking for an existing one"

        if master = find_master_user_for(user_info[:email])
          logger.warn "\tOk, found a Pibi user with that email, I'll use that as a master."
          master_creation.output = master
        else
          logger.warn "\tUh, no candidate Pibi user found, accepting as a detached slave."
          return rc.accept slave
        end
      end

      logger.warn "Oki, created a Pibi user to use as a master for this new user coming from #{provider}."
      master = master_creation.output
      slave.link_to(master)
    # A returning user authenticating using a 3rd-party account
    elsif !new_user && current_user.nil?
      logger.debug "\tUser had been previously registered, gonna use its master link [#{slave.link.try(:id)}]"
      master = slave.link

      if master.nil?
        logger.warn "\tNo master found! I'll try to look for one..."
        master_creation = find_or_create_master_for(user_info)

        unless master_creation.successful?
          logger.warn "\t\tUnable to find a master for this user, gonna bail."
          return rc.reject master_creation.error
        end

        master = master_creation.output
        slave.link_to(master)
      end
    # Linking a 3rd-party account, current_user is the master in this case
    elsif current_user.present?
      logger.debug "\tUser had been previously registered, and has an active session (#{current_user.id}), linking..."
      master = current_user
      slave.link_to(master)
    end

    rc.accept master
  end

  def update(user, params)
    params[:token] = params.delete(:reset_password_token)
    params.delete(:id)

    unless user.update(params)
      return reject_with user.errors
    end

    accept_with user
  end

  def destroy(user)
    unless user.destroy
      reject_with user.errors
    end

    accept_with true
  end

  def create_emergency_savings_package(user)
    emergency_account = user.accounts.create({
      label: EMERGENCY_ACCOUNT_LABEL
    })

    budget_service = BudgetService.new
    budget_service.create(user, {
      name: EMERGENCY_BUDGET_NAME,
      goal: "savings_control",
      account_id: emergency_account.id,
      every: 1,
      interval: "months",
      quantifier: 5,
      is_ratio: true,
      favorite: true
    })
  end

  protected

  def oauth_to_user_hash(provider, auth)
    random_password = generate_random_password

    {
      provider: provider,
      uid: auth.uid.to_s,
      name: auth.info.name,
      email: auth.info.email || auth.email,
      password: random_password,
      password_confirmation: random_password
    }
  end

  def find_master_user_for(email)
    User.find_by({ email: email, provider: 'pibi' })
  end

  def find_or_create_master_for(user_info)
    svc = Result.new
    if master = find_master_user_for(user_info[:email])
      svc.accept(master)
    else
      creation_svc = create(user_info.merge({ provider: 'pibi' }))

      unless creation_svc.successful?
        return svc.reject creation_svc.error
      end
    end
  end

  def generate_random_password
    (Base64.urlsafe_encode64 Random.rand(1234 * (10**3)).to_s(8)).to_s.sanitize
  end
end