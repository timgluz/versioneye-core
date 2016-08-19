#!/bin/bash

echo "Going to run all specs"
export RAILS_ENV="test"
echo "Rails mode: $RAILS_ENV"

rspec # spec/versioneye/services/notification_service_spec.rb

export RAILS_ENV="development"
echo "Rails mode: $RAILS_ENV"
