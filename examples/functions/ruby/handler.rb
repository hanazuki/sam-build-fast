require 'bundler/setup'
require 'nokogiri'

def main(*)
  puts "We have #{RUBY_DESCRIPTION} and nokogiri #{Nokogiri::VERSION}."
end
