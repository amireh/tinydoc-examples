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

# @API Currencies
#
# Every transaction tracked by Pibi requires a currency to be set. We maintain
# a list of 165+ currencies, with their rates synced on a daily basis as per
# the registry in [OpenExchangeRates](https://openexchangerates.org/).
#
# When hosting Pibi yourself, you will need an OpenExchangeRates API key to
# be able to retrieve the currencies.
#
# @object Currency
#  {
#    // ISO Code of the currency.
#    "name": "USD",
#
#    // A symbol to use as an alternative to the ISO Code of the currency
#    "symbol": "$",
#
#    // The exchange rate of this currency to the global USD one
#    "rate": 1.0
#  }
class CurrenciesController < ApplicationController
  before_filter :require_user

  # @API Retrieving all available currencies
  #
  # Note that this endpoint is not paginated; you will receive all available
  # currencies in the response document.
  #
  # @returns [ Currency ]
  def index
    currencies = Currency.all
    params[:per_page] = currencies.length
    expose currencies
  end
end