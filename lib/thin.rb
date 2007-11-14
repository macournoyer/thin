$:.unshift File.dirname(__FILE__)
require 'logger'
require 'rubygems'

require 'thin/consts'
require 'thin/status'
require 'thin/mime_types'
require 'thin/server'
require 'thin/request'
require 'thin/response'
require 'thin/handler'
require 'thin/cgi'
require 'thin/rails'
