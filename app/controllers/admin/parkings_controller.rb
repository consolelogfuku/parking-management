class Admin::ParkingsController < Admin::BaseController
  before_action :set_parking, only: %i[show edit update destroy]

  def index
    @parkings = Parking.includes(:user).order(created_at: :desc)
  end

  def show
  end

  def new
    @parking = Parking.new
  end

  def create
    @parking = Parking.new(parking_params)
    if @parking.save
      redirect_to admin_parkings_path, notice: "駐車場を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @parking.update(parking_params)
      redirect_to admin_parkings_path, notice: "駐車場を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @parking.destroy
    redirect_to admin_parkings_path, notice: "駐車場を削除しました"
  end

  private

  def set_parking
    @parking = Parking.find(params[:id])
  end

  def parking_params
    params.require(:parking).permit(:name, :status, :phone_number, :user_id)
  end
end
