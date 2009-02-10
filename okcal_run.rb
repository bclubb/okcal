#!/usr/bin/env ruby
require 'rubygems'
require './okcal.rb'

cal = OKCal.new
cal.new_event('daily','test1','20090215')
cal.new_event('daily','test1','20090215', {'stop' => '2009-03-18'})
cal.new_event('weekly','test3','20090215',{'stop' => '2009-03-18', 'frequency' => 3})
cal.new_event('weekly','test4','20090215',{'stop' => '2009-03-18', 'frequency' => ['Monday','Thursday']})
cal.new_event('monthly','test5','20090215',{'stop' => '2009-12-12', 'frequency' => 0})
cal.new_event('monthly','test6','2009-12-18',{'stop' => '2010-12-18', 'frequency' => 'last', 'day' => 'Tuesday'})
cal.new_event('yearly','test7','2009-12-18',{'stop' => '2018-12-18'})
cal.new_event('yearly','test8','2009-12-18')
# To get a date do: cal.get_events(<date>)
events = cal.get_events('2009-02-16')
print events