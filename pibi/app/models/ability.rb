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

class Ability
  include CanCan::Ability

  def initialize(user)
    return false unless user.present?

    user_id = user.id

    can :manage, User, { id: user_id }
    can :manage, [
      Account,
      Budget,
      Category,
      PaymentMethod
    ], { user_id: user_id }

    # Account resources
    can :manage, [ Transaction, Recurring ] do |transaction|
      can? :manage, transaction.account
    end

    can :manage, Attachment do |attachment|
      can? :manage, attachment.transaction
    end
  end
end
