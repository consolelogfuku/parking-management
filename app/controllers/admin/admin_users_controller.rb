class Admin::AdminUsersController < Admin::BaseController
  before_action :set_admin_user, only: %i[edit update destroy]

  def index
    @admin_users = AdminUser.order(created_at: :desc)
  end

  def new
    @admin_user = AdminUser.new
  end

  def create
    @admin_user = AdminUser.new(admin_user_params)
    if @admin_user.save
      redirect_to admin_admin_users_path, notice: "管理者を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    params_to_use = admin_user_params
    params_to_use = params_to_use.except(:password, :password_confirmation) if params_to_use[:password].blank?
    if @admin_user.update(params_to_use)
      redirect_to admin_admin_users_path, notice: "管理者を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin_user.destroy
    redirect_to admin_admin_users_path, notice: "管理者を削除しました"
  end

  private

  def set_admin_user
    @admin_user = AdminUser.find(params[:id])
  end

  def admin_user_params
    params.require(:admin_user).permit(:email, :password, :password_confirmation)
  end
end
