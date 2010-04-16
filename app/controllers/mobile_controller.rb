class MobileController < ApplicationController
  trans_sid :always
  session :cookie_only => false
  mobile_filter :hankaku=>true
  protect_from_forgery :only => "none"
  layout "mobile"

  verify :session => :member, :redirect_to => "/mobile/login", 
    :except => [:login, :authenticate]
  before_filter :set_xhtml_header

  include TwitterHelper

  def xhtml_supported
    case request.mobile
    when Jpmobile::Mobile::Docomo
      return true if request.env["HTTP_USER_AGENT"] =~ /^DoCoMo\/(\d)/ && $1.to_i >= 2
    when Jpmobile::Mobile::Au
      return true if request.env["HTTP_USER_AGENT"] =~ /^KDDI-/
    when Jpmobile::Mobile::Softbank
      case request.env["HTTP_USER_AGENT"]
      when /^J-PHONE\/5/, /^Vodafone\/1/, /^SoftBank\/1/
        return true
      end
    end
    false
  end

  def set_xhtml_header
    headers["Content-type"] = "application/xhtml+xml" if xhtml_supported
  end

  def recent
    member_id = current_member.id

    sql = <<SQL
SELECT member_id, items.id AS iid, items.link AS ilink, items.title AS ititle,
       feeds.id AS fid, feeds.title AS ftitle
FROM subscriptions, feeds, items
WHERE subscriptions.member_id = ? AND 
  subscriptions.feed_id = feeds.id AND
  items.feed_id = feeds.id AND
  items.created_on > ?
ORDER BY subscriptions.feed_id, items.created_on DESC;
SQL
    @recordset = Item.find_by_sql [sql, member_id, Time.now - 60*60*24*4]

    item_ids = @recordset.map do |r| r.iid end
    @subs = @recordset.map do |r|
      {:id => r.fid, :title => r.ftitle}
    end.uniq
    if @subs.empty? then render NOTHING; return; end

    sql2 = <<SQL
SELECT item_id, view_count 
FROM item_members
WHERE item_id IN (?) AND member_id = ? ;
SQL
    rs = ItemMembers.find_by_sql [sql2, item_ids, member_id]
    @view_counts = rs.inject({}) do |h, im|
      h[im.item_id] = im.view_count
      h
    end

    session.delete :item_id
  end

  def last
    redirect_to current_member.last_url
  end

  def list
    unless params[:item_id]
      if param = session[:item_id] then
        redirect_to :action => :list , :item_id => param,
          :page_num => params["page_num"]
      else 
        redirect_to :action => :recent
      end
      return
    end
    current_member.last_url = request.request_uri
    current_member.save

    item_ids = []
    id2order = {}

    params[:item_id].keys.map do |param|
       param.split("-").map do |s|
         s.to_i(36)
       end
    end.each do |order, id|
      item_ids << id
      id2order[id] = order
    end
    items = Item.find :all, :conditions => ["id IN (?)" , item_ids],
       :select => "id, title, link, html, bytesize, created_on"
    item_hash = {}
    item_ids  = []
    items.each do |item|
      item_hash[item.id] = item
      item_ids << item.id
    end

    @page_to_show = params[:page_num].to_i || 0

    slice_num = 3
    cur_page = 0
    size = 0
    max = 80_000
    si = SiteInfo.new

    @htmls = []
    @items_to_show = []
    @to_be_continued = false
    catch(:break) do
      item_ids.sort_by do |id|
        id2order[id]
      end.each_slice(slice_num) do |item_ids|
        GC.start
        threads = item_ids.map do |item_id|
          item = item_hash[item_id]
          if item.html.nil? or item.html.empty?
            Thread.start(item) do |i|
              i.html = html = si.integrate_html(i.link)
              i.save
              [html, nil]
            end
          else
            [item.html, item.bytesize]
          end
        end

        threads.zip(item_ids).each do |t, item_id|
          item = item_hash[item_id]
          html, bytesize = t.is_a?(Thread) ? t.value : t
          unless bytesize then
            bytesize = html_bytesize(html)
            item.bytesize = bytesize
            item.save
          end
          bytesize ||= 0
          size += bytesize
          if cur_page == @page_to_show then
            @htmls << html
            @items_to_show << item
            im = ItemMembers.find_or_create_by_item_id_and_member_id item.id, current_member.id
            im.view_count += 1
            im.save
          end
          if max <= size then
            if cur_page == @page_to_show then
              @to_be_continued = true
              throw :break
            end
            size = 0
            cur_page += 1
          end
        end
      end
    end
    session[:item_id] = params[:item_id]
    session[:referer] = request.request_uri
  end

  def accept_bugreport
    if params[:item_id].nil?
      rediect_to :action => list
      return
    end

    ids = params[:item_id].keys
    member_id = current_member.id
    ids.each do |item_id|
      iid = item_id.split("-").last.to_i
      b = BugReport.find_or_initialize_by_item_id_and_member_id iid, member_id do |b|
        b.member_id = member_id
        b.item_id = params[:id]
        b.user_comment = "failure"
      end
      b.save
      session[:item_id].delete item_id
    end

    redirect_to :action => "list"
  end

  def twitter
    member = current_member
    if member.twitter_access_token then
      twitter_list
    else
      url = twitter_authorize_url
      redirect_to url
      return
    end
  end

  def twitter_list
    rubytter = current_rubytter
    filename = File.join(RAILS_ROOT, "config", "twitter.yaml")
    tw = YAML::load(open(filename).read)
    @page = params["page"].to_i || 0
    pagenum = tw["PAGE_NUM"]

    @statuses = []
    retry_count = 0
    1.upto(pagenum) do |i|
      num = @page*pagenum + i
      begin 
        rubytter.friends_timeline(:page => num).each do |status|
          @statuses << status
        end
      rescue
        retry_count += 1
        retry if retry_count < 2
      end
    end
  end

  def twitter_callback
    access_token, secret = 
      twitter_access_token params[:oauth_token], params[:oauth_verifier]
    member = current_member
    member.twitter_access_token = access_token
    member.twitter_access_token_secret = secret
    member.save
    redirect_to :action => "twitter"
  rescue OAuth::Unauthorized => e
    flash[:notice] = "oauth failed"
    redirect_to :action => "twitter"
  end

  def send_twit
    if params[:twit] then
      rubytter = current_rubytter
      msg = params[:twit]
      rubytter.update msg
    end
    redirect_to :action => :twitter
  end

  def login
    if logged_in?
      redirect_to :action => "index"
      return
    elsif request.mobile? and ident = request.mobile.ident
      member = Member.find_by_ident ident
      self.current_member = member
      @current_user = nil
      if logged_in?
        redirect_to :action => "index"
        return
      end
    elsif request.mobile? and
      request.mobile.is_a? Jpmobile::Mobile::Docomo and 
      params[:guid].nil?
      redirect_to :action => "login", "guid" => "on"
      return
    end
  end

  def signout
    self.current_member.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been signed out."
    render :action => "login"
  end

  def authenticate
    self.current_member = member = 
      Member.authenticate(params[:username], params[:password])
    if logged_in?
      if params[:remember_me] == "1" and request.mobile?
        member.ident = request.mobile.ident 
        member.save
      end
      redirect_to :action => "index"
    else
      redirect_to :action => "login"
    end
  end
end
