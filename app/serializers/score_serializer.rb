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