# == Schema Information
#
# Table name: scores
#
#  id         :integer          not null, primary key
#  score      :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ScoreSerializer
  include FastJsonapi::ObjectSerializer
  
  attributes :score, :created_at, :updated_at
  
  belongs_to :user
  
  attribute :user_name do |score|
    score.user&.name
  end
  
  attribute :device do |score|
    score.user&.device
  end
end 
