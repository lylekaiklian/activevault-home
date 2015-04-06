class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  before_filter :add_headers
  
  def add_headers
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Accept"] = "application/json"
    
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type, X-Requested-With'
    
    #http://arnab-deka.com/posts/2012/09/allowing-and-testing-cors-requests-in-rails/
    head(:ok) if request.request_method == "OPTIONS"
  end
  
end
