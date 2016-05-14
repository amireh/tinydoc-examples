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

class PaymentMethodService < Service
  def create(user, params)
    params.delete(:id)
    payment_method = user.payment_methods.create(params)

    unless payment_method.valid?
      return reject_with payment_method.errors
    end

    accept_with payment_method
  end

  def update(payment_method, params)
    params.delete(:id)

    if params.default
      payment_method.user.payment_methods.where({ default: true }).update({
        default: false
      })
    end

    unless payment_method.update(params)
      return reject_with payment_method.errors
    end

    accept_with payment_method
  end

  def destroy(payment_method)
    unless payment_method.destroy
      return reject_with payment_method.errors
    end

    accept_with nil
  end
end
