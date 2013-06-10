# Make sure you have Sinatra installed, then start sidekiq with
# ./bin/sidekiq -r ./examples/sinkiq.rb
# Simply run Sinatra with
# ruby examples/sinkiq.rb
# and then browse to http://localhost:4567
#
require 'sinatra'
require './lib/cap_runner'
require './lib/deployer_worker'
require 'timeout'

get '/output' do
  begin
    Timeout::timeout(5) do
      loop do
        sleep(1)
        break if CapRunner.started?
      end
    end
  rescue Timeout::Error
    halt 'Looks like nothing is running yet'
  end
  stream do |out|
    out << '<pre>'
    CapRunner.stream_output do |line|
      out << line
    end
    out << '</pre>'
  end
end

get '/clear' do
  CapRunner.finish!
  "Cleared up the pid file"
end

before /deploy/ do
  if CapRunner.started?
    halt 'Something is already running'
  end
end

{'deploy' => '/deploy', 'setup' => '/deploy/setup', 'install' => '/deploy/install' }.each do |method, url|
  get "/now#{url}" do
    stream do |out|
      out << '<pre>'
      CapRunner.send(method, out)
      out << '</pre>'
    end
  end

  get url do
    DeployerWorker.perform_async(:task => method)
    "See the output here <a href=\"/output\">here</a>"
  end
end
