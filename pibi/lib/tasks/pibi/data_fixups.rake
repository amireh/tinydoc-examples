namespace :pibi do
  namespace :data_fixups do
    desc 'remove unused preference keys from user preferences'
    task :user_preferences => [:environment] do
      DataFixup::PortUserPreferences.new.run
    end
  end
end