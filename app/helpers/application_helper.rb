module ApplicationHelper
  def info(election)
    info = ''
    info << election.attributes.values_at("jurisdiction", "election_type").join(' ')
    info << ', '+election.division if election.division 
    info
  end

end
