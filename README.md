# ProblematicVariableFinder
## Usage

It is recommended that you use this as a standalone script. It has some dependencies
which will be irrelevant to your project, and ironically this library isn't focused
on achieving thread safety in and of itself.

```bash
problematic_variable_finder --help
```



## Examples

```bash
problematic_variable_finder --ignore=rails,activerecord,activesupport --verbose
```


Problem:

We want to upgrade to puma but we don't know if our code is thread safe.

What does it mean when code is not thread safe?

Simply put: When you have any shared  state that is modified in one request, 
and then read in another request, you can get unexpected results.

Here shared state can mean anything. E.g.
browser local storage, cookies, database, cache, ruby class instance variables, global variables etc.,

This gem focuses solely on static analysis of ruby code to find 
* class instance variables
* class variables
* global variables

These are among some of the most common reasons for thread safety issues.

imagine the following code:

```ruby
 1: module Authorization
 2:   def self.authorized?(user)
 3:     @user = user
 4::   
 5:     case @user
 6:     when Admin
 7:       true
 8:     else
 9:       false
10:     end
11:   end
```


if one request comes in for an ordinary user, and another request comes in for an admin,
here on line 3 we are setting a class instance variable initially with the ordinary user.

The admin user's thread comes in and calls `Authorization.authorized?` shortly afterwards
and then gets to line 3 it will overwrite `@user` for the first thread.

Then on line 5 the ordinary user thread will authorize as an Admin instead.


Solution:
Find all potential global variables in your codebase.
And mitigate the above kind of scenarios.
Finding potential issues is all this gem does.
You will thne need to go through and audit each of the potential issues.

If you imagine a thread safety issue is a snake. Then a global variable is long grass.
This gem is a long grass detector.
So whilst the Rails codebase is thread safe, it does still contain global variables.
But as long as a global variables



This is a simple script that will find all global, class variables, class instance variables in your 
application and gem dependencies.


## Installation

```ruby
gem 'problematic_variable_finder'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-analysis/problematic_variable_finder.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
