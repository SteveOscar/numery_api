class UsersController < ApplicationController
  include ApiResponse

  # before_action :set_user, only: [:update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    render_success(UserSerializer.new(@users).serializable_hash)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    # params[:id] is device id
    @user = User.find_by(device: params[:id])
    if @user
      render_success(UserSerializer.new(@user).serializable_hash)
    else
      render_error("User not found", status: :not_found)
    end
  end

  # POST /users
  # POST /users.json
  def create
    create_params = JSON.parse(request.raw_post)
    @user = User.new(create_params)
    if @user.save
      render_success(UserSerializer.new(@user).serializable_hash, status: :created)
    else
      render_errors(@user.errors.full_messages, status: :unprocessable_entity)
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
