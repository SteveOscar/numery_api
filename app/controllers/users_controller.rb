class UsersController < ApplicationController
  # before_action :set_user, only: [:update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    render json: @users
  end

  # GET /users/1
  # GET /users/1.json
  def show
    # params[:id] is device id
    @user = User.find_by(device: params[:id])
    render json: @user
  end

  # POST /users
  # POST /users.json
  def create
    create_params = JSON.parse(request.raw_post)
    @user = User.new(create_params)
    if @user.save
      render json: @user
    else
      render json: {errors: @user.errors}, status: :unprocessable_entity
    end
  end

  private
    # def set_user
    #   @user = User.find(params[:id])
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email, :device)
    end
end
