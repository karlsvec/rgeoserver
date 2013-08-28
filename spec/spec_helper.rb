require 'awesome_print'
require 'equivalent-xml'
require 'rspec'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.join(File.dirname(__FILE__), '../config/boot')
