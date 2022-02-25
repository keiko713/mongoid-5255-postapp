#!/bin/sh
bundle exec unicorn -p 4567 -c ./config/unicorn.rb
