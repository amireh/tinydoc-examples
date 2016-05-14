Pibi::Application.routes.draw do
  if Rails.env.development?
    mount MailPreview => 'mails'
  end

  scope controller: :currencies do
    get '/currencies', action: :index
  end

  scope controller: :authentication do
    scope '/sessions' do
      get '/', action: :show
      post '/', action: :create
      put '/', action: :refresh
      delete '/', action: :destroy
      delete '/:sink', action: :destroy
    end

    get '/auth/failure', to: 'authentication#oauth_failure'
    get '/auth/:provider/callback', to: 'authentication#authorize_by_oauth'
  end

  scope '/access_tokens', controller: :access_tokens do
    get '/', action: :index, as: :user_access_tokens
    post '/', action: :create
    get '/:udid', action: :show, as: :user_access_token
    delete '/:udid', action: :destroy
  end

  scope '/users', controller: :users do
    post '/', action: :create
    get '/reset_password', action: :reset_password, as: :user_reset_password
    post '/change_password', action: :change_password, as: :user_change_password
    get '/:user_id', action: :show, as: :user
    patch '/:user_id', action: :update
    delete '/:user_id', action: :destroy
    delete '/:user_id/links', action: :unlink, as: :user_unlink_provider
    get '/:user_id/verify_email', action: :verify_email, as: :user_verify_email

    scope '/:user_id/privacy_policy', controller: :privacy_policies do
      get '/', action: :show, as: 'privacy_policy'
      get '/metrics', action: :all_metrics
      patch '/', action: :update, as: 'update_privacy_policy'
    end

    scope '/:user_id/accounts', controller: :accounts do
      post '/', action: :create
      get '/', action: :index, as: 'user_accounts'
      get '/:account_id', action: :show, as: 'user_account'
      patch '/:account_id', action: :update
      delete '/:account_id', action: :destroy
    end

    scope '/:user_id/categories', controller: :categories do
      post '/', action: :create
      get '/', action: :index, as: 'user_categories'
      get '/:category_id', action: :show, as: 'user_category'
      patch '/:category_id', action: :update
      delete '/:category_id', action: :destroy
    end

    scope '/:user_id/payment_methods', controller: :payment_methods do
      post '/', action: :create
      get '/', action: :index, as: 'user_payment_methods'
      get '/:payment_method_id', action: :show, as: 'user_payment_method'
      patch '/:payment_method_id', action: :update
      delete '/:payment_method_id', action: :destroy
    end

    scope '/:user_id/journals', controller: :journals do
      post '/', action: :create
      get '/', action: :index, as: 'user_journals'
      get '/:journal_id', action: :show, as: 'user_journal'
    end

    scope '/:user_id/notices', controller: :notices do
      get '/:token', action: :accept, as: :user_notice_accept
    end

    scope '/:user_id/budgets', controller: :budgets do
      post '/', action: :create
      get '/', action: :index, as: 'user_budgets'
      get '/favorites', action: :favorites, as: 'user_favorite_budgets'
      get '/:budget_id', action: :show, as: 'user_budget'
      patch '/:budget_id', action: :update
      delete '/:budget_id', action: :destroy
    end
  end

  scope '/budgets/:budget_id/transactions', controller: :budgets do
    get '/', action: :transactions, as: 'budget_transactions'
  end

  scope '/accounts/:account_id' do
    scope '/transactions', controller: :transactions do
      get '/', action: :index, as: 'account_transactions'
      get '/:transaction_id', action: :show, as: 'account_transaction'
      post '/', action: :create
      patch '/:transaction_id', action: :update
      delete '/:transaction_id', action: :destroy
    end

    scope '/recurrings', controller: :recurrings do
      get '/', action: :index, as: 'account_recurrings'
      get '/:recurring_id', action: :show, as: 'account_recurring'
      post '/', action: :create
      patch '/:recurring_id', action: :update
      delete '/:recurring_id', action: :destroy
    end
  end

  scope '/accounts/transfers', controller: :transactions do
    post '/', action: :transfer, as: 'create_account_transfer'
  end

  [ 'transactions', 'recurrings' ].each do |attachable|
    key = attachable.singularize
    scope "/#{attachable}/:#{key}_id/attachments", controller: :attachments do
      post '/', action: :create
      get '/', action: :index, as: "#{key}_attachments"
      get '/:attachment_id', action: :show, as: "#{key}_attachment"
      get '/:attachment_id/item', action: :serve_item, as: "#{key}_attachment_item"
      delete '/:attachment_id', action: :destroy
    end
  end

  scope '/progresses', controller: :progresses do
    get '/:progress_id', action: :show, as: 'progress'
  end

  scope '/exports', controller: :exports do
    post '/transactions', to: :transactions, as: 'export_transactions'
  end

  scope '/attachments', controller: :attachments do
    get '/:attachment_id', action: :show, as: "attachment"
  end

  scope '/transactions', controller: :transactions do
    get '/', action: :mega_index, as: 'cross_account_transactions'
  end

  scope '/recurrings', controller: :recurrings do
    get '/upcoming', action: :upcoming, as: 'upcoming_recurrings'
  end

  match '*path' => 'application#rogue_route', via: :all
  match '/' => 'application#rogue_route', via: :all
end
