class Workers::ExportTransactions
  DateFormat = '%d-%m-%Y'

  def self.perform(args)
    puts "Creating CSV for transactions: #{args}"

    user = User.find(args['user_id'])
    attachment = Attachment.find(args['attachment_id'])

    from = Pibi::Util.parse_date(args['from'], Time.now.beginning_of_month)
    from = from.beginning_of_day

    to = Pibi::Util.parse_date(args['to'], Time.now.end_of_month)
    to = to.end_of_day

    format = args['format'] || 'csv'

    transactions = Transaction.where(account_id: args['account_ids']).occurred_in(from, to)

    puts "Exporting #{transactions.size} transactions"
    exporter = TransactionExporter.new
    csv = exporter.to_csv(transactions)

    csv_file = Tempfile.new([ 'transactions', 'csv' ])
    csv_file.write(csv)
    csv_file.close

    attachment.item = File.open(csv_file.path)
    attachment.item_content_type = 'text/csv'
    attachment.item_file_name = self.generate_filename(from, to, format)
    attachment.save!

    FileUtils.rm(csv_file)

    attachment.progress.update_attributes({
      workflow_state: 'complete',
      completion: 100
    })

    Pibi::Messenger.publish(user.id,  ClientMessage::ExportTransactions, {
      attachment_id: "#{attachment.id}",
      progress_id: "#{attachment.progress.id}",
      download_url: attachment.absolute_item_url
    }, {
      client_id: args['client_id']
    })
  end

  def self.generate_filename(from, to, ext)
    filename = [
      'Pibi',
      'Transactions',
      from.strftime(DateFormat),
      '-',
      to.strftime(DateFormat)
    ].join(' ')

    [ filename, ext ].join('.')
  end
end