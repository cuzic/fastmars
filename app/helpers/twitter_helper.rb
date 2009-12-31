module TwitterHelper
  require 'oauth'
  require 'rubytter'

  def twitter_oauth_consumer
    filename = File.join(RAILS_ROOT, "config", "twitter.yaml")
    tw_secret = YAML::load(open(filename).read)
    consumer = OAuth::Consumer.new(
      tw_secret["consumer_key"],
      tw_secret["consumer_secret"],
      :site => 'http://twitter.com/'
    )
    return consumer
  end

  def twitter_authorize_url
      consumer = twitter_oauth_consumer
      url = url_for :action => "twitter_callback", :only_path => false
      request_token = consumer.get_request_token(
        :oauth_callback => url
      )
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      return request_token.authorize_url
  end

  def twitter_access_token token, verifier
    request_token = OAuth::RequestToken.new(
      twitter_oauth_consumer,
      session[:request_token],
      session[:request_token_secret]
    )

    session[:request_token] = nil
    session[:request_token_secret] = nil

    access_token = request_token.get_access_token({},
        :oauth_token => token,
        :oauth_verifier => verifier
    )
    return access_token.token, access_token.secret
  end

  def current_rubytter
    consumer = twitter_oauth_consumer
    member = current_member
    token = session[:twitter_access_token] ||= \
      member.twitter_access_token
    secret = session[:twitter_access_token_secret] ||= \
      member.twitter_access_token_secret
    token = OAuth::AccessToken.new(
      consumer, token, secret
    )
    rubytter = OAuthRubytter.new(token)
    return rubytter
  end
end
