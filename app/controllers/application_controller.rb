class ApplicationController < ActionController::Base
	include Magick
	include Digest
  include ApplicationHelper

  protect_from_forgery
  prepend_before_filter   :clrscr
  before_filter           :authenticate
  after_filter            :save_shit

  def not_found_action
  	not_found
  end

  def banned
    if banned?
      render :template => 'banned'
    else
      redirect_to :root
    end
  end

  private
  def banned?
    @ip_address['ban'] != nil
  end

  def not_found
  	render :template => 'not_found'
  end

  def authenticate
    @ip_address = REDIS.get "ip_#{request.remote_ip}"
    if not @ip_address
      @ip_address = {
        'ip'        => request.remote_ip,
        'ban'       => nil,
        'last_post' => nil,
      }
      REDIS.set "ip_#{request.remote_ip}", @ip_address.to_json
    else
      @ip_address = JSON.parse @ip_address
    end
    puts @ip_address.inspect
    if cookies.has_key? 'settings'
      @settings = REDIS.get "settings_#{cookies['settings']}"
      if not @settings
        set_settings
      else
        @settings = JSON.parse @settings
      end
    else
      set_settings
    end
    @anal = false
    if cookies.has_key? 'anal'
      if challenge = REDIS.get(cookies['anal'])
        if $admin_passwords.include? challenge
          @anal = true
        end
      end
    end
  end

  def set_settings
    key = MD5.hexdigest SALT + rand.to_s + Time.new.to_s
    @settings = {
      'key'       => key,       'seen'      => Hash.new,
      'settings'  => Hash.new,  'hidden'    => Array.new,
      'favs'      => Array.new
    }
    cookies['settings'] = {
      :value    => @settings['key'],
      :path     => root_path,
      :expires  => Time.new + 99999999
    }
    REDIS.set "settings_#{@settings['key']}", @settings.to_json
  end

  def save_shit
    REDIS.set "settings_#{@settings['key']}", @settings.to_json
    REDIS.set "ip_#{request.remote_ip}", @ip_address.to_json
  end

  def clrscr
    puts 
    puts '_' * 100
  end

  def captcha_correct?
    link = 'http://www.google.com/recaptcha/api/verify'
    return Net::HTTP.post_form(URI.parse(link), {
      'privatekey' => RCC_PRIV,
      'remoteip' => request.remote_ip,
      'challenge' => params['recaptcha_challenge_field'],
      'response' => params['recaptcha_response_field'],
    }).body == "true\nsuccess"
  end
end