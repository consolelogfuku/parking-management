class Admin::DashboardController < Admin::BaseController
  def index
    @user_count = User.count
    @parking_count = Parking.count
    @admin_user_count = AdminUser.count
  end
end
