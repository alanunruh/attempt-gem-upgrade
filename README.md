# attempt-gem-upgrade
A simple class to help you upgrade gems.
The idea behind this very simple tool is to upgrade a gem, run the test suite, and if things fail revert and then move on to the next gem in the list. If the test suite doesn't fail after an upgrade, commit the changes and move on to the next gem in the list. 

*I set this up to run over night so I can work while I sleep. In the morning I get a listing of all the gems that broke my build.

Example usage:
~ irb

`gems = ['pry', 'listen', 'bullet']`
`require '/path/to/attempt_gem_upgrade.rb'`
`upgrade = AttemptGemUpgrade.new(gems)`
`upgrade.rock_and_roll`

Rake Task Example Usage:

`rake 'gems:attempt_update["GEMS:THAT:SHOULD:NOT:BE:UPDATED"]'`