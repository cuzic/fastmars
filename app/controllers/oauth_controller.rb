class OauthController < ApplicationController
  require 'oauth'
  require 'json'

  def self.twitter_oauth_consumer
    filename = File.join(RAILS_ROOT, "config", "twitter.yaml")
    tw_secret = YAML::load(open(filename).read)
    consumer = OAuth::Consumer.new(
      tw_secret["consumer_key"],
      tw_secret["consumer_secret"],
      :site => 'http://twitter.com'
    )
    return consumer
  end

  def verify
    request_token = OauthController.consumer.get_request_token(
      :oauth_callback => "http://#{request.host_with_port}/oauth/callback"
    )
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url
    return
  end

  def callback
    request_token = OAuth::RequestToken.new(OauthController.consumer,
                                            session[:request_token],
                                            session[:request_token_secret])
    access_token = request_token.get_access_token({},
                                                  :oauth_token => params[:oauth_token],
                                                  :oauth_verifier => params[:oauth_verifier])
    res = OauthController.consumer.request(:get,
                                           '/account/verify_credentials.json',
                                           access_token, {:scheme => :query_string})
    case res
    when Net::HTTPSuccess
      user_info = JSON.parse(res.body)
      unless user_info['screen_name']
        flash[:notice] = "login failed"
      else
        user = current_user
        user.token = access_token.token
        user.secret_token = access_token.secret
        user.save!
        flash[:notice] = "Twitter login success"
        redirect_to user_path(current_user)
      end
    else
      flash[:notice] = "login failed"
    end
  end
end
