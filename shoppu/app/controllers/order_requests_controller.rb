class OrderRequestsController < ApplicationController
  before_action :logged_in_user #, only: [:create, :destroy]

  before_action only: [:correct_user, :show, :edit, :update, :destroy] do
     set_order_request("from_owner")
  end

  before_action only: [:accept] do
    set_order_request("from_all")
  end

  before_action only: [:show_one_accepted] do
    set_order_request("from_servicer")
  end

  before_action :correct_admin, only: [:hide, :show_all]

  # For users; Set all un-accepted orders by users
  def show_open
    # Selects open order_requests which have a positive number of order_items
    #  AND which belong to other users
    @order_requests = OrderRequest.select { |order_request| \
                      order_request.status == "open" && \
                      order_request.order_items.all.size > 0 && \
                      order_request.owner_id != current_user.id }
  end

  # For admins; Set all order requests made by all users
  def show_all
    @order_requests = OrderRequest.select {|order_request| order_request.status != "hidden"}
  end

  # For users who are servicers
  def show_all_accepted
    set_all("accepted")
  end

  # For user who is a servicer
  def show_one_accepted
  end

  # For user who is a servicer
  def show_all_completed
    set_all("completed")
  end

  # For user who is a servicer
  def accept
    if @order_request.update_attributes(:servicer_id => current_user.id, :status => "accepted")
      flash[:success] = 'Order request was successfully accepted.'
      set_all("accepted")
      render('show_all_accepted')
    else
      flash[:error] = "Failed to accept order - Please try again [0x0103]"
      redirect_to @user
    end
  end

  # For user who is a owner
  def index
    @order_requests = OrderRequest.all
  end

  # For user who is a owner
  def show
  end

  # For users
  def new
    @order_request = current_user.owned_orders.build
  end

  # For users
  def edit
  end

  # For users
  def create
    @order_request = current_user.owned_orders.build(order_request_params)

    respond_to do |format|
      if @order_request.save
        format.html { redirect_to @order_request, notice: 'Order request was successfully created.' }
        format.json { render :show, status: :created, location: @order_request }
      else
        format.html { render :new }
        format.json { render json: @order_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # For user who is a owner
  def update
    respond_to do |format|
      if !@order_request.update_attributes(order_request_params)
        format.html { render :edit }
        format.json { render json: @order_request.errors, status: :unprocessable_entity }
      end
      flash[:success] = "Order has been updated"
      format.html { redirect_to @order_request }
    end
  end

  # For admin
  def hide
    @order_request = OrderRequest.find_by_id(params[:id])
    @order_request.update_attributes(:status => "hidden")

    redirect_to order_requests_show_all_path
  end

  # For user who is a owner
  def destroy
    @order_request.destroy
    respond_to do |format|
      format.html { redirect_to order_requests_url, notice: 'Order request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_order_request(from_type)
      if from_type == "from_owner"
        @order_request = current_user.owned_orders.find_by_id(params[:id])
      elsif from_type == "from_servicer"
        @order_request = current_user.serviced_orders.find_by_id(params[:id])
      elsif from_type == "from_all"
        @order_request = OrderRequest.find_by_id(params[:id])
      else # force method to fail
        @order_request = nil
      end

      if @order_request.blank?
        flash[:error] = "A processing error has occurred - Sorry for the inconvenience [0x0100]"
        redirect_to root_url
        return
      end
    end

    # Selects order requests of a certain status which are serviced by current_user
    def set_all(status_type)
      @order_requests = OrderRequest.select { |order_request| \
                        order_request.status == status_type && \
                        order_request.servicer_id == current_user.id}
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_request_params
      params.require(:order_request).permit(:title, :bounty, :deliver_by, :accepted_at, :service_rating, :status, :description, :address, :longitude, :latitude)
    end

    def correct_admin
      if (!current_user.is_moderator?)
        flash[:error] = "A processing error has occurred - Sorry for the inconvenience [0x0102]"
        redirect_to root_url
      end
    end
end
