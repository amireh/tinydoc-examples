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
# @API PaymentMethods
#
# Payment methods are a way to identify **how you paid or received money**.
#
# For example, if you bought a pair of shoes using a credit card, you can mark
# that transaction with a Credit Card payment method. If you have multiple
# credit cards and you'd like to distinguish them, you can simple add each
# credit card you own as a payment method, assign it a color, and be good to go.
#
# @object PaymentMethod
#  {
#    // The unique id of the payment_method.
#    "id": 1,
#
#    // A unique name for the payment_method.
#    "name": "Household",
#
#    // An emblem to associate with the payment_method by front-end clients when
#    // a payment_method is displayed (or a transaction tagged by it).
#    "color": "FF0000",
#
#    "media": {
#      // Path to this payment_method.
#      "url": "/users/2/payment_methods/1",
#      // Path to the user this payment_method belongs to.
#      "user": "/users/2"
#    },
#
#    // ID of the user this payment_method belongs to.
#    "user_id": 2
#  }
class PaymentMethodsController < ApplicationController
  include Rack::API::Resources
  include Rack::API::Parameters

  before_filter :require_user
  before_filter :require_payment_method, except: [ :index, :create ]
  before_filter :prepare_service, except: [ :index, :show ]

  def index
    expose current_user.payment_methods
  end

  # @API Creating payment methods
  #
  # @argument [String] name
  #   A unique name for the payment_method.
  #
  # @argument [String] color (optional)
  #   RGB color in hex to associate with the payment method.
  #
  # @returns
  #   {
  #     "payment_methods": Array( [PaymentMethod]() )
  #   }
  def create
    parameter :name, type: :string, required: true
    parameter :color, type: :string

    with_service @service.create(current_user, api.parameters) do |payment_method|
      expose payment_method
    end
  end

  def show
    expose @payment_method
  end

  # @API Update a payment_method.
  def update
    accepts :name, :color, :default

    with_service @service.update(@payment_method, api.parameters) do |payment_method|
      expose payment_method
    end
  end

  def destroy
    with_service @service.destroy(@payment_method) do |rc|
      no_content!
    end
  end

  private

  def prepare_service
    @service = PaymentMethodService.new
  end

  def require_payment_method
    with :user, :payment_method
  end
end