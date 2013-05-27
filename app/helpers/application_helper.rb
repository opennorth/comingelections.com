module ApplicationHelper
  def info(election)
    info = ''
    info << election.attributes.values_at("jurisdiction", "election_type").join(' ')
    info << ', '+election.attributes.values_at("division", "scope", "notes").join(', ') 
    info = info.gsub(/ ,/,'')
  end

end
