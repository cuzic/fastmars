class ReaderController < ApplicationController
  before_filter :redirect_if_mobile

  verify :session => :member, :redirect_to => "/login"
  layout nil, :only => :index

  def welcome
    redirect_to :action => :index, :trailing_slash => true
  end

  def index
  end

  private
  def redirect_if_mobile
    if request.mobile?
      pa = params.dup
      pa[:controller] = "mobile"
      pa[:action] = "login"
      redirect_to pa
    end
  end
end
