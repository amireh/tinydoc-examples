namespace :doc do
  desc 'generate docs using yard-api'
  task :api => :environment do
    require 'yard-api'
    require 'yard-api/yardoc_task'
    require 'yard-api-slatelike'

    runner = YARD::APIPlugin::YardocTask.new(:pibi_api_docs)
    output = runner.config['output']
    Rake::Task['pibi_api_docs'].invoke
    puts <<-Message
      API Documentation successfully generated in #{output}
      See #{output}/index.html
    Message
  end

  desc 'generate JSON docs using yard-api'
  task :api_json => :environment do
    require 'yard-api'
    require 'yard-api/yardoc_task'
    require 'yard-api-slatelike'

    runner = YARD::APIPlugin::YardocTask.new(:pibi_api_json_docs) do |t|
      t.configure({ format: 'json', verbose: true, debug: true })
    end

    output = runner.config['output']
    Rake::Task['pibi_api_json_docs'].invoke
    puts <<-Message
      API Documentation successfully generated in #{output}
      See #{output}/index.html
    Message
  end
end
