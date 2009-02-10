# Calendar code for 

## irb example
#require 'okcal.rb'
#cal = OKCal.new
#cal.new_event('daily','test1','20090215')
#cal.new_event('monthly','test5','20090215',{'stop' => '2009-12-12', 'frequency' => 0})
#
#
## End irb exampple

##Here is a script that uses the code
# #!/usr/bin/env ruby
# require 'rubygems'
# require './okcal.rb'
# 
# cal = OKCal.new
# cal.new_event('daily','test1','20090215')
# cal.new_event('daily','test1','20090215', {'stop' => '2009-03-18'})
# cal.new_event('weekly','test3','20090215',{'stop' => '2009-03-18', 'frequency' => 3})
# cal.new_event('weekly','test4','20090215',{'stop' => '2009-03-18', 'frequency' => ['Monday','Thursday']})
# cal.new_event('monthly','test5','20090215',{'stop' => '2009-12-12', 'frequency' => 0})
# cal.new_event('monthly','test6','2009-12-18',{'stop' => '2010-12-18', 'frequency' => 'last', 'day' => 'Tuesday'})
# cal.new_event('yearly','test7','2009-12-18',{'stop' => '2018-12-18'})
# cal.new_event('yearly','test8','2009-12-18')
# # To get a date do: cal.get_events(<date>)
# events = cal.get_events('2009-02-16')
print events


#class to make events and get them out
class OKCal 
  attr_reader :cal,:events, :error

  def initialize
    @cal = {}
    @events = {}
  end
  
  def new_event(type,name,start,params = {})
    if @events.key?(name)
      @error = 'Error '+type.downcase+" name '#{name}' taken"
      puts @error
      return nil
    end
    begin
      add_event(OKEvent.new(type,name, start, params))
    rescue OKEventException=>error
      @error = "Error adding event #{name} - "+error
      puts @error
      return nil
    end
    
  end
  
  def add_event(event)
    @events[event.name] = event
    event.days.each do |d|
        if !@cal.key?(d)
          @cal[d] = []
        end
        @cal[d] << event.name

    end
  end
  def get_events(date)
    d = Date.parse(date)
    
    
    return 'Events on '+date.to_s+":\n"+@cal[d.to_s].join("\n")
  end
end

#event class populates the days hash for the calendar
class OKEvent 
  attr_reader :type, :name, :start, :end, :frequency, :days

    
  #initialize the event and parse the opts to make sure they are valid
  def initialize(type,name,start, params = {})
    @days = Array.new
    #the array we will hand back
    @name = name
    @type = check_type(type)
    check_params(params)
    (@start,@stop) = check_dates(start,@stop)
    send(type)
    @day_mark = nil
  end
  
  #methods for all the types, returns list of days to add to the 
  def daily
    if @frequency
      raise OKEventException, 'Daily events don\'t take frequency option'
    end
    if @stop.nil?
      @days << self.start.to_s
      return(self)
    end
    @day_mark = @start
    while @day_mark <= @stop
      @days << @day_mark.to_s
      @day_mark += 1
    end
  end
  
  def weekly
    valid_days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    if @stop.nil?
      raise OKEventException, 'weekly Events must have a stop date'
    end
    if !@frequency.nil?
      if ((!@frequency.is_a?(Integer)) && (!@frequency.is_a?(Array)))
        raise OKEventException, 'Invalid frequency for weekly type'
      else
        if @frequency.is_a?(Array)
          @frequency.each do |f|
            if !valid_days.include?(f)
              raise OKEventException, f+' isn\t a valid frequency for weekly type'
            end
          end
        end
      end
    else
      @frequency = 1
    end
   
    if @frequency.is_a?(Array)
       @day_mark = @start
       while @day_mark <= @stop
          if @frequency.include?(valid_days[@day_mark.wday])
            @days << @day_mark.to_s
          end
          @day_mark += 1
        end
        return
    end
    
    if @frequency.is_a?(Integer)
      @day_mark = @start
      @day_count = 0
       while @day_mark <= @stop
         @day_count += 1
         @days << @day_mark.to_s
         if(@day_count % 7 == 0)
           @day_mark += (@frequency-1)*7
         else
           @day_mark += 1
         end
        
      end
      return
    end
    raise OKEventException, 'Unable to process event'
  end
  
  def monthly
    valid_days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    valid_ons = ["first", "second", "third", "last"]
    if @stop.nil?
      raise OKEventException, 'Monthly events must have a stop date'
    end
    
    if !@frequency.nil?
      if ((!@frequency.is_a?(Integer)) && (!@frequency.is_a?(String)))
        raise OKEventException, 'Invalid frequency for monthly type'
      end
    else
      @frequency = 0
    end
    
    if @frequency.is_a?(String)
      if @day.nil?
        raise OKEventException, 'Must day param when frequency is a day string'
      end
      if !valid_ons.include?(@frequency.downcase)
        raise OKEventException, 'Invalid "on the" in frequency for monthly type'
      end
      if !valid_days.include?(@day)
        raise OKEventException, 'Invalid "on the" in frequency for monthly type'
      end
      find_mdays(valid_days,valid_ons)
      return
    end
    
    if @frequency.is_a?(Integer)
      if !@day.nil?
        raise OKEventException, 'Can\'t pass day param when frequency isn\'t an integer'
      end
      
      #special cause for freuncy 0, just add the day
      if @frequency == 0
        @days << @start.to_s
        return
      end
      
      #go find the days month by month based on frequency
      @day_mark = @start
      while @day_mark <= @stop
       @days << @day_mark.to_s
       @day_mark = @day_mark >> @frequency
      end
      return

      
    end
    raise OKEventException, 'Unable to process event'
  end
  
  def yearly
    if !@frequency.nil?
      raise OKEventException, 'Year events have no frequency'
    end
    if !@day.nil?
      raise OKEventException, 'Year events have no day param'
    end
    if @stop.nil?
      @stop = Date.new(@start.year, 12, 30)
    end
    
    @day_mark = @start
    while @day_mark <= @stop
        @days << @day_mark.to_s
        @day_mark = Date.new(@day_mark.year+1, @day_mark.mon, @day_mark.day)
    end
  end
  
  #methods to help find days 
  def find_mdays(vdays,ons)
    @find_wday = vdays.index(@day)
    @find_on = ons.index(@frequency)
    #get the current month for the start month
    
    
    @find_day =  get_month_wdays(@start.year,@start.mon,@find_wday,@find_on)

    #if the first day we are suppose to find is past fast forward
    if @find_day < @start
      next_month = @start >> 1
      @m_track = Date.new(next_month.year,next_month.mon)
      @find_day = get_month_wdays(@m_track.year,@m_track.mon,@find_wday,@find_on)
    else
      @m_track = @start
    end

    while @m_track <= @stop
      if @m_track == @find_day
        @days << @m_track.to_s
        next_month = @m_track >> 1
        @m_track = Date.new(next_month.year,next_month.mon)
        @find_day = get_month_wdays(@m_track.year,@m_track.mon,@find_wday,@find_on)
      else
        @m_track += 1
      end
    end
  end
  
  def get_month_wdays(year,month,wday,frequency)
    #special case for last
    if frequency == 4
      last_day = Date.new(year, month) -1
      return Date.new(year, month, (last_day.day-wday))
    end
    
    month_mark = Date.new(year,month, 1)
    @occurance = 0
    while month_mark < Date.new(year,month, -1)
      if month_mark.wday == wday
         if @occurance == frequency
           return month_mark
         end
         @occurance += 1
      end
      month_mark += 1
    end

    
  end
  
  # methods to check input and sometimes do stuff with it
  def check_type(type)
    if (type =~ /^daily|weekly|monthly|yearly$/i).nil?
      raise OKEventException, 'Unknown event type'
    end
    return type
  end
  
  def check_params(params)
    valid = ['stop', 'frequency', 'day']
    params.each_key do |key| 
      if !valid.include?(key)
        raise OKEventException, 'Invalid param: '+key
      end
    end
    valid.each do |key|
      instance_variable_set("@#{key}",params[key])
    end
  end
  
  def check_dates(start,stop=nil)
    begin
      s = Date.parse(start)
    rescue ArgumentError
      raise OKEventException, 'Start date is invalid'
    end
    if stop.nil?
      return (s)
    end
    begin
      e = Date.parse(stop)
    rescue ArgumentError
      raise OKEventException, 'End date is invalid'
    end
    if e < s
      raise OKEventException, 'End date is before start date'
    end
    return([s,e])
  end

end
#exceptions are nice
class OKEventException < Exception
end


