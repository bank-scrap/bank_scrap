require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  pwd = Dir.pwd

  specs = Dir['bank_scrap-*/'].map do |submodule|
    name = submodule.sub('bank_scrap-', '').sub('/', '')
    task = [name, 'spec'].join(':')

    folder = File.expand_path(submodule)

    task name do
      Dir.chdir(folder)
    end

    desc "Run RSpec for #{name} module"
    RSpec::Core::RakeTask.new(task) do |task|
      task.fail_on_error = true # TODO: set it to false, and collect all results
    end

    # chdir before running the spec and change back after
    Rake::Task[task].enhance([name]) do
      Dir.chdir(pwd)
    end

    task
  end

  task default: specs + [:spec]

rescue LoadError
end
