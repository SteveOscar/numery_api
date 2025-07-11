class UserSerializer
  include FastJsonapi::ObjectSerializer
  
  attributes :name, :email, :device, :created_at, :updated_at
  
  has_many :scores
  
  attribute :score_count do |user|
    user.scores.count
  end
  
  attribute :best_score do |user|
    user.scores.maximum(:score) || 0
  end
end 