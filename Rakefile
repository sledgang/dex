task :install do
  sh 'bundle install --path vendor/bundle --binstubs'
end

task :default do
  sh 'bundle exec ruby src/dex.rb'
end

task :pry do
  sh 'bundle exec ruby src/dex.rb pry'
end

task :build do
  sh 'docker build -t dex .'
end
