namespace :gems do
  desc "Attempt to upgrade gems that can be upgraded"
  task :attempt_upgrade, [:ignored_gems]  => :environment do |t, args|
    ignored_gems = args.with_defaults(ignored_gems: "")[:ignored_gems].split(':')
    @gems = gems_to_attempt_upgrading(ignored_gems)
    @original_commit = ""
    @skipped_gems = []
    @failed_gems = []
    @upgraded_gems = []
    attempt_gem_upgrade
  end
end

def gems_to_attempt_upgrading(ignored_gems)
  fetch_all_gems - ignored_gems
end

def fetch_all_gems
  Bundler::Definition.build('Gemfile', nil, {}).dependencies.map { |gem| gem.name }
end

def attempt_gem_upgrade
  puts 'This is experimental software. Use at your own risk. Any damage to your code base is not my fault!'
  puts '#######'
  puts '#######'
  puts 'Are you sure you want to proceed? Type YES to continue, any other input will exit.'
  user_input = STDIN.gets.chomp
  unless user_input == 'YES'
    puts 'Did not recieve YES, exiting.'
    return
  end

  unless clean_working_tree?
    puts 'A clean working tree is required. Please commit your changes before you continue.'
    return
  end

  @original_commit = current_commit
  @gems.each do |gem|
    upgrade_gem(gem)
  end

  puts 'All Done! 😸'
  puts ''

  puts '######'
  puts "#{@upgraded_gems.count} gems were upgraded. Would you like to display them? Y/N"
  if STDIN.gets.chomp.downcase == 'y'
    @upgraded_gems.each do |gem|
      puts gem
    end
    puts ''
    puts ''
  end

  puts '######'
  puts "#{@skipped_gems.count} gems did not require upgrades. Would you like to display them? Y/N"
  if STDIN.gets.chomp.downcase == 'y'
    @skipped_gems.each do |gem|
      puts gem
    end
    puts ''
    puts ''
  end

  puts '######'
  puts "#{@failed_gems.count} gems broke rspec. Would you like to display them? Y/N"
  if STDIN.gets.chomp.downcase == 'y'
    @failed_gems.each do |gem|
      puts gem
    end
    puts ''
    puts ''
  end
  puts ''
  puts ''

  puts '######'
  puts 'If this broke your app please run the following command to get back to where we started.'
  puts "git reset --hard #{@original_commit}"
end

def upgrade_gem(gem)
  fallback_commit = current_commit
  puts "Upgrading gem: #{gem}"
  if upgrade_required?(gem)
    puts "## Upgrading required"
    if bundler_update_gem(gem)
      if rspec_green?
        puts "## Rspec pased!"
        commit_changes(gem)
        @upgraded_gems << gem
      else
        puts "## Rspec failed"
        @failed_gems << gem
        reset_to_commit(fallback_commit)
      end
    else
      puts "## Upgrade failed"
      @failed_gems << gem
      reset_to_commit(fallback_commit)
    end
  else
    puts "## Upgrade not required"
    @skipped_gems << gem
  end
end

def clean_working_tree?
  `git status`.include?('nothing to commit, working tree clean')
end

def current_commit
  `git rev-parse HEAD`.chomp
end

def upgrade_required?(gem)
  `bundle outdated #{gem}`.include?('Outdated gems included in the bundle:')
end

def bundler_update_gem(gem)
  puts "## Attempting update"
  system("bundle update #{gem}")
end

def rspec_green?
  system('rspec --fail-fast')
end

def reset_to_commit(commit)
  `git reset --hard #{commit}`
end

def commit_changes(gem)
  `git commit -am '#{gem} was upgraded. Automatic commit.'`
end
