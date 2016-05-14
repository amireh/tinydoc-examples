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

##
# @API Categories
#
# An interface for managing a user's transaction categories.
#
# Categories provide a way for both you and Pibi to categorize and structure your
# financial activity. They can be extremely helpful when reporting your data,
# as well as when you're browsing your activity in the activity feed.
#
# While you can attach notes to your transactions (and you really should!), use
# categories to classify your transactions, and attach notes to them to remind
# you exactly of what each single transaction was for.
#
# @object Category
#  {
#    // The unique id of the category.
#    "id": 1,
#
#    // A unique name for the category.
#    "name": "Household",
#
#    // An emblem to associate with the category by front-end clients when
#    // a category is displayed (or a transaction tagged by it).
#    //
#    // @see Appendix: Emblems for the available icons.
#    "icon": "house",
#
#    // Path to this category.
#    "href": "/users/2/categories/1",
#
#    "links": {
#      // Path to the user this category belongs to.
#      "user": "/users/2"
#    },
#
#    // ID of the user this category belongs to.
#    "user_id": 2
#  }
class CategoriesController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_category, except: [ :index, :create ]
  before_filter :prepare_service, except: [ :index, :show ]

  def index
    expose current_user.categories
  end

  # @API Create a new category.
  #
  # @argument [String] name
  #   A unique name for the category.
  # @argument [String] icon (optional)
  #   An icon to associate with the category.
  #
  # @returns
  #   {
  #     "category": Category
  #   }
  def create
    parameter :name, type: :string, required: true
    parameter :icon, type: :string

    with_service @service.create(current_user, api.parameters) do |category|
      expose category
    end
  end

  def show
    expose @category
  end

  # @API Update a category.
  def update
    accepts :name, :icon

    with_service @service.update(@category, api.parameters) do |category|
      expose category
    end
  end

  def destroy
    with_service @service.destroy(@category) do |rc|
      no_content!
    end
  end

  private

  def prepare_service
    @service = CategoryService.new
  end

  def require_category
    with :user, :category
  end
end