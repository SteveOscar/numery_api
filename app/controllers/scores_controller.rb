class ScoresController < ApplicationController
  include ApiResponse

  before_action :set_user, only: [:create]
  before_action :clean_data, only: [:high_scores]

  def high_scores
    results = get_high_scores
    render_success(results)
  end

  def create
    @score = @user.scores.new(score: score_params["score"])

    if @score.save
      render_success(ScoreSerializer.new(@score).serializable_hash, status: :created)
    else
      render_errors(@score.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def get_high_scores
    results = {}
    user = User.find_by(device: params["device"])
    scores = Score.includes(:user).order("score DESC").limit(20)

    results["high_scores"] = scores.map do |s|
      {
        name: s.user.name,
        score: s.score,
        device: s.user.device
      }
    end

    results["user_score"] = if user && user.scores.any?
                              user.scores.maximum(:score)
                            else
                              0
                            end

    results
  end

  def clean_data
    Score.where(user_id: nil).delete_all
  end

  def set_user
    @user = User.find(score_params["user"])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def score_params
    params.permit(:score, :user, :device)
  end
end
