module DataFixup
  class PortUserPreferences
    def run
      User.all.each do |user|
        # we'll maintain the currencies
        preferences = user.preferences.slice(:currencies).merge({
          theme: 'vanilla'
        })

        User.connection.execute(<<-SQL
          UPDATE users SET
            preferences='#{preferences.to_json.to_s}'
          WHERE id=#{user.id}
        SQL
        )
      end
    end
  end
end