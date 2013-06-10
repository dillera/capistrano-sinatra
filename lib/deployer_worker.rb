require 'sidekiq'
require File.expand_path('../cap_runner', __FILE__)

class DeployerWorker
  # To change this template use File | Settings | File Templates.
  include Sidekiq::Worker
  def perform(opts = {'task' => 'deploy'})
    CapRunner.send(opts['task'].to_sym)
  end
end