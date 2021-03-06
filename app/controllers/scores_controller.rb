class ScoresController < ApplicationController
  before_action :set_user, only: [:create]
  before_action :clean_data, only: [:high_scores]

  def high_scores
    results = get_high_scores
    render json: results
  end

  def create
    @score = @user.scores.new(score: score_params['score'])

    if @score.save
      render json: @score
    else
      render json: @score.errors, status: :unprocessable_entity
    end
  end


  private
    def get_high_scores
      results = {}
      user = User.find_by(device: params['device'])
      scores = Score.order('score').reverse_order.limit(5)
      results['high_scores'] = scores.map { |s| [s.user.name, s.score] }
      results['user_score'] = (user && user.scores.length > 0) ? user.scores.order('score').last.score : 0
      results
    end

    def clean_data
      Score.where(user_id: nil).delete_all
    end

    def set_user
      @user = User.find(score_params['user'])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def score_params
      params.permit(:score, :user, :device)
    end
end
