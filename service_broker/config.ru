# This rack config file is used to start the service broker application
# when it is deployed as an application on Cloud Foundry

require './skeleton_broker_app'
run SkeletonBrokerApp.new
