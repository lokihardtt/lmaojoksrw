require 'open-uri'
require 'nokogiri'

class HistoryController < ApplicationController
  before_action :authenticate_user!

  def index
    @histories = Transaction.where("username = :username OR receiver = :username", username: current_user.username).order("created_at DESC").page(params[:page])
  end
end
