class Date
  # @see http://api.rubyonrails.org/classes/Date.html#method-i-days_to_week_start
  def days_to_week_start(start_day)
    (start_day - wday) % 7
  end

  def years_to_term_start(start_year, term_length)
    (start_year - year) % term_length
  end
end
