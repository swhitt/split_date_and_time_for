module SplitDateAndTimeFor
  def self.enable
    ActionView::Base.send :include, ModelHelpers
  end
  
  module ModelHelpers
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def split_date_and_time_for(name, options = {})
        attr_writer :"#{name}_day"
        attr_writer :"#{name}_time"

        zone = (options[:time_zone] && ActiveSupport::TimeZone[options[:time_zone]]) || Time.zone

        define_method(name.to_sym) {  read_attribute(name).try(:in_time_zone, zone) }

        define_method("#{name}_day") {  instance_variable_get("@#{name}_day") || send(name).try(:strftime, '%d %b %Y') }

        define_method("#{name}_time") {  instance_variable_get("@#{name}_time") || send(name).try(:strftime, '%I:%M %p') }

        before_validation do |record|
          record.set_time_attribute(name.to_sym, record.send("#{name}_day"), record.send("#{name}_time"), zone)
        end

      end
    end

    def set_time_attribute(atr_name, day, time, input_zone)
      return if day.blank? || time.blank?
      st_day = Date.parse(day)
      st_time = Time.parse(time)
      write_attribute(atr_name,
      input_zone.local(st_day.year, st_day.month, st_day.day, st_time.hour, st_time.min, st_time.sec))
    rescue ArgumentError
    end
  end
end


if defined?(ActiveRecord)
  SplitDateAndTimeFor.enable
end