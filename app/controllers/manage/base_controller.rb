class Manage::BaseController < ApplicationController
  before_action :authenticate_user!

  layout "manage"
end
