# Include hook code here
require "wordstreamify"

ActiveRecord::Base.send(:include, Wordstreamify)