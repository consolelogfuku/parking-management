require "prawn"

class Manage::ParkingsController < Manage::BaseController
  before_action :set_parking, only: %i[edit update destroy qr qr_pdf]

  def index
    @parkings = current_user.parkings.order(created_at: :desc)
  end

  def new
    @parking = current_user.parkings.build
  end

  def create
    @parking = current_user.parkings.build(parking_params)
    if @parking.save
      redirect_to manage_parkings_path, notice: "駐車場を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @parking.update(parking_params)
      redirect_to manage_parkings_path, notice: "駐車場を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @parking.destroy
    redirect_to manage_parkings_path, notice: "駐車場を削除しました"
  end

  def qr
    if ENV["NGROK_HOST"].present?
      @public_url = "https://#{ENV['NGROK_HOST']}/public/#{@parking.id}"
    else
      @public_url = public_parking_url(@parking.id)
    end
  end

  def qr_pdf
    public_url = if ENV["NGROK_HOST"].present?
      "https://#{ENV['NGROK_HOST']}/public/#{@parking.id}"
    else
      public_parking_url(@parking.id)
    end

    qr = RQRCode::QRCode.new(public_url)
    qr_png = qr.as_png(size: 600, border_modules: 0)

    pdf = Prawn::Document.new(page_size: "A4") do |doc|
      doc.font_families.update(
        "NotoSansJP" => { normal: Rails.root.join("app", "assets", "fonts", "NotoSansJP-Bold.ttf").to_s }
      )
      doc.font "NotoSansJP"

      doc.move_down 120
      doc.text @parking.name, size: 28, align: :center
      doc.move_down 40
      doc.image StringIO.new(qr_png.to_s), fit: [300, 300], position: :center
    end

    send_data pdf.render, filename: "qr_#{@parking.name}.pdf", type: "application/pdf", disposition: "attachment"
  end

  private

  def set_parking
    @parking = current_user.parkings.find(params[:id])
  end

  def parking_params
    params.require(:parking).permit(:name, :status, :phone_number)
  end
end
