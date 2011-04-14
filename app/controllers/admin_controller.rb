class AdminController < ApplicationController
	before_filter :anal_auth

	def index
	end

	def delete
		return not_found if not request.post?
		begin
			post = Post.find params[:id].to_i
		rescue
			return not_found
		end
		post.exterminate		
		redirect_to :root
	end

	def update
		return not_found if not request.post?
		begin
			post = Post.find params[:id].to_i
		rescue
			return not_found
		end
		post.message = params[:message]
		post.save
		if params[:ban] == 'on'
			@ip_address['ban'] = {
				:given		=> Time.now,
				:expires 	=> Time.now + (86400 * params[:ban_days].to_i),
				:reason		=> params[:ban_reason]
			}
		end
		redirect_to :action => 'post', :id => post.id
	end

	def login
		if request.post?
			challenge = MD5.hexdigest SALT + params[:password]
			if $admin_passwords.include? challenge
				session = MD5.hexdigest challenge + rand.to_s
				cookies[:anal] = {
					:value 	=> session,
					:path		=> root_path
				}
				REDIS.set session, challenge
				redirect_to :root
			else
				redirect_to :action => 'index', :trailing_slash => true
			end
		end
	end

	def logout 
		cookies.delete 	:anal
		redirect_to 		:root
	end

	def post
		begin 
			@post = Post.find params[:id].to_i
		rescue
			return not_found
		end
	end

	def toggle_captcha
		return not_found if not request.post?
		if $settings[:captcha] == false
			$settings[:captcha] = true
		else
			$settings[:captcha] = false
		end
		redirect_to :action => 'index', :trailing_slash => true
	end

	private
	def anal_auth
		if params[:action] != 'login'
			return not_found if not @anal
		end
	end
end
