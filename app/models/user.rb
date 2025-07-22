# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  device     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  has_many :scores, dependent: :destroy

  validates :device, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  # validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Scopes for common queries
  scope :with_scores, -> { joins(:scores).distinct }
  scope :top_players, ->(limit = 10) {
    joins(:scores)
      .group("users.id")
      .order("MAX(scores.score) DESC")
      .limit(limit)
  }

  # Instance methods
  def best_score
    scores.maximum(:score) || 0
  end

  def average_score
    scores.average(:score) || 0
  end

  def score_count
    scores.count
  end

  def recent_scores(limit = 5)
    scores.order(created_at: :desc).limit(limit)
  end

  # Class methods
  def self.find_by_device_or_create(device_params)
    find_or_create_by(device: device_params[:device]) do |user|
      user.name = device_params[:name]
      # user.email = device_params[:email]
    end
  end
end
