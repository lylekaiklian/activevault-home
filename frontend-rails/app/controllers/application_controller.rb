class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  before_filter :add_headers
  
  def add_headers
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Accept"] = "application/json"
  end
  
end
