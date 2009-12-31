# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'oauth'
  require 'rubytter'

  def loadJS(*filename)
    filename.map {|str|
      %Q{<script type="text/javascript" src="/js/#{str}.js" charset="utf-8"></script>}
    }.join("\n")
  end

  def disp_users(num)
    "#{num} #{(num > 1 ? "users" : "user")}"
  end

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
      url = "http://#{request.host_with_port}/mobile/twitter_callback"
      request_token = consumer.get_request_token(
        :oauth_callback => url
      )
      session[:request_token] = request_token.token
      session[:request_token_secret] = request_token.secret
      return request_token.authorize_url
  end

  def twitter_access_token oauth_token, oauth_verifier
    request_token = OAuth::RequestToken.new(
      self.class.twitter_oauth_consumer,
      session[:request_token],
      session[:request_token_secret]
    )

    session[:request_token] = nil
    session[:request_token_secret] = nil

    begin
      access_token = request_token.get_access_token({},
        :oauth_token => oauth_token,
        :oauth_verifier => oauth_verifier
      )
      return access_token.token, access_token.secret
    rescue OAuth::Unauthorized => e
      return
    end
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
