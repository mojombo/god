God: The Ruby Framework for Process Management
==============================================

* By Tom Preston-Werner, Kevin Clark, Eric Lindval
* Website at http://god.rubyforge.org

Description
-----------

God is an easy to configure, easy to extend monitoring framework written in
Ruby.

Keeping your server processes and tasks running should be a simple part of
your deployment process. God aims to be the simplest, most powerful monitoring
application available.

Documentation
-------------

See online documentation at http://god.rubyforge.org

Community
---------

Sign up for the god mailing list at http://groups.google.com/group/god-rb

Install
-------

    $ sudo gem install god

Contribute
----------

Latest code is available at http://github.com/mojombo/god

The 'master' branch can be cloned with:

    $ git clone git://github.com/mojombo/god

Once you have the code locally, install dependencies and run tests:

    $ cd god
    $ bundle install
    $ bundle exec rake

The best way to get your changes merged back into core is as follows:

1. Fork my repo on GitHub
1. Clone down your fork
1. Create a thoughtfully named topic branch to contain your change
1. Hack away
1. Add tests and make sure everything still passes by running `bundle exec rake`
1. If you are adding new functionality, document it in the docs
1. Do not change the version number, I will do that on my end
1. If necessary, rebase your commits into logical chunks, without errors
1. Push the branch up to GitHub
1. Send a pull request to the mojombo/god project

License
-------

See LICENSE file.
