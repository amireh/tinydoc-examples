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

class BudgetService < Service
  def create(user, params)
    params.delete(:id)
    budget = user.budgets.create(params)

    unless budget.valid?
      return reject_with budget.errors
    end

    accept_with budget
  end

  def update(budget, params)
    params.delete(:id)
    unless budget.update(params)
      return reject_with budget.errors
    end

    accept_with budget
  end

  def destroy(budget)
    unless budget.destroy
      return reject_with budget.errors
    end

    accept_with nil
  end
end
