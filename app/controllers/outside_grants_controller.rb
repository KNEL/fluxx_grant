class OutsideGrantsController < ApplicationController
  def index
    org = Organization.find(params[:id])
    @data = org.outside_grants
    render :index, :layout => nil
  end
end
