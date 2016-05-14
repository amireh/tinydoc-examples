module Pibi::Worker
  def self.enqueue(worker_klass, job_params)
    Resque.enqueue_to('pibi_jobs', worker_klass, job_params)
  end
end