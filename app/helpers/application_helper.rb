module ApplicationHelper
  WEEKDAYS = %w[sunday monday tuesday wednesday thursday friday saturday]
  MONTHS = %w[January February March April May June July August September October November December]
  SUFFIXES = %w[st nd rd th]


  def info(election)
    info = ''
    info << election.attributes.values_at("jurisdiction", "election_type").join(' ')
    info << ', '+election.division if election.division 
    info
  end


  def schedule_info(election)
    string = ''
    if election.rank > 0  
      string << "the #{election.rank}#{SUFFIXES[election.rank-1]} "
    else
      string << "the last"
    end

    string << "#{WEEKDAYS[election.weekday]} of #{MONTHS[election.month-1]}, "
    string << "every #{election.term_length} years"
    string
  end

end
