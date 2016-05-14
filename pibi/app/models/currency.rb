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

class Currency < ActiveRecord::Base
  default_scope { order('name ASC') }

  paginates_per 200
  max_paginates_per 200

  before_save :set_defaults

  def set_defaults
    self.symbol ||= self.name
  end

  class << self
    def valid?(iso_code)
      Currency.where({ name: iso_code }).any?
    end

    def [](iso_code)
      Rails.cache.fetch(Currency.cache_key(iso_code)) do
        Currency.find_by({ name: iso_code })
      end
    end

    def cache_key(iso_code)
      "currency_#{iso_code}"
    end
  end

  # converts an amount from an original currency to this one
  #
  # @param [String|Currency] currency
  #   Either the ISO code of a currency, or an actual currency.
  def from(currency, amount)
    currency = Currency[currency] if currency.is_a?(String)
    (currency.normalize(amount) * self.rate).round(DECIMAL_SCALE)
  end

  # converts an amount from this currency to another one
  # curr can be a String or a Currency
  def to(currency, amount)
    currency = Currency[currency] if currency.is_a?(String)
    currency.from(self, amount)
  end

  # converts the given amount to USD based on this currency rate
  def normalize(amount)
    amount.to_f / self.rate
  end
end
