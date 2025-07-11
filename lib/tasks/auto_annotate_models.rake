if defined?(Annotate)
  namespace :db do
    task :migrate => :environment do
      Rake::Task["annotate_models"].invoke
    end
    task :rollback => :environment do
      Rake::Task["annotate_models"].invoke
    end
  end
end 