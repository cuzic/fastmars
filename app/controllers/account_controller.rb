class AccountController < ApplicationController
  verify :session => :member, :redirect_to => "/login"

  include TwitterHelper

  def password
    if request.post?
      unless @member.authenticated?(params[:password])
        @member.errors.add :password, "is invalid"
        return
      end
      @member.crypted_password = ""
      @member.password = params[:new_password]
      @member.password_confirmation = params[:new_password_confirmation]
      @member.save
    end
  end

  def twitter
    member = current_member
    if  member.twitter_access_token then
      flash[:notice] = "access token is already set"
      render :action => :index
    else
      url = twitter_authorize_url
      redirect_to url
    end
  end

  def twitter_callback
    access_token, secret = 
      twitter_access_token params[:oauth_token], params[:oauth_verifier]
    member = current_member
    member.twitter_access_token = access_token
    member.twitter_access_token_secret = secret
    member.save
    flash[:notice] = "twitter oauth setting done"
    redirect_to :action => "index"
  rescue OAuth::Unauthorized => e
    flash[:notice] = "oauth failed"
    redirect_to :action => "index"
  end
end
