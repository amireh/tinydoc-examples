# require 'ext/active_record'
# require 'ext/action_dispatch'
# require 'core_ext'
require 'action_dispatch/request'

String.include CoreExt::String
ActiveRecord::Base.include Ext::ActiveRecord::Base