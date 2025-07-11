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
class Score < ApplicationRecord
  belongs_to :user
  
  validates :score, presence: true, numericality: { greater_than: 0 }
  
  scope :high_scores, ->(limit = 10) { order(score: :desc).limit(limit) }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
  scope :by_user, ->(user) { where(user: user) }
  
  def rank
    Score.where('score > ?', score).count + 1
  end
  
  def percentile
    total_scores = Score.count
    return 100 if total_scores == 0
    
    better_scores = Score.where('score > ?', score).count
    ((total_scores - better_scores).to_f / total_scores * 100).round(2)
  end
  
  # Class methods
  def self.global_high_scores(limit = 10)
    includes(:user).high_scores(limit)
  end
  
  def self.user_high_scores(user, limit = 5)
    by_user(user).high_scores(limit)
  end
  
  def self.average_score
    average(:score) || 0
  end
  
  def self.median_score
    scores = pluck(:score).sort
    return 0 if scores.empty?
    
    if scores.length.odd?
      scores[scores.length / 2]
    else
      (scores[scores.length / 2 - 1] + scores[scores.length / 2]) / 2.0
    end
  end
end
