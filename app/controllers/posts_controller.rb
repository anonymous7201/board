class PostsController < ApplicationController
  def index
    page_number = 1
    if params[:number]
      if /^\d+$/ === params[:number]
        page_number = params[:number].to_i
        if [0, 1].include? page_number
          return redirect_to :root
        end
      else
        return not_found
      end
    end
    @posts = Post.get_page page_number
    if @posts.empty? and page_number != 1
      return not_found
    end
  end

  def view
    begin
      post = Post.find params[:id].to_i
    rescue ActiveRecord::RecordNotFound
      return not_found
    else
      if not post.root?
        url = url_for :action => 'view', :id => post.root_id
        redirect_to url + "##{post.id}" and return
      else
        if @settings['seen'].has_key? params[:id]
          if post.replies > @settings['seen'][params[:id]]
            @new = @settings['seen'][params[:id]] + 1
          end
        end
        if @settings['seen'].has_key? params[:id]
          @seen = @settings['seen'][params[:id]]
          if post.replies > @seen
            @new = post.replies - @seen
          else
            @new = 0
          end
        end
        @settings['seen'][params[:id]] = post.replies
        @op_post = post
        @replies = post.get_replies
      end
    end
  end

  def create
    if request.post?
      return render :text => process_post(true)
    end
  end

  def reply
    if request.post?
      result = process_post false
      if result == true
        @settings['seen'][params[:id]] += 1 if @settings
        return render :partial => 'post', :object => @post
      else
        return render :text => result
      end
    else
      return not_found
    end
  end

  def get_post
    if not request.post?
      redirect_to :action => 'view', :id => params[:id]
    else
      begin
        post = Post.find params[:id].to_i
      rescue
        return render :text => '0'
      end
      return render :partial => 'post', :object => post
    end
  end

  private
  def process_post op_post=false
    cookies[:password] = {
      :value    => params[:password],
      :path     => root_path,
      :expires  => Time.new + 99999999
    }
    errors = Array.new
    if banned?
      return t('error.banned')
    end
    if @ip_address['last_post']
      if not Time.now.to_i > @ip_address['last_post'] + 5
        return t('error.fastpoke')
      end
    end
    if $settings[:captcha] and op_post and not captcha_correct?
      return t('error.captcha')
    end
    picture_result = process_picture
    if picture_result.kind_of? Array
      errors += picture_result
    end
    post = Post.new do |post|
      post.message    = params[:message].strip
      post.ip         = request.remote_ip
      post.author     = @settings['key']
    end
    if op_post
      if picture_result == nil
        errors << t('error.no_picture')
      end
      if post.message.empty?
        errors << t('error.no_message')
      end
    else
      begin
        parent      = Post.find params[:id].to_i
        post.number = parent.replies + 1
      rescue ActiveRecord::RecordNotFound
        return t('error.parent_not_found')
      else
        post.parent_id  = parent.id
      end     
      if post.message.empty? and picture_result == nil
        errors << t('error.no_content')
      end
      if params[:sage] == 'on'
        post.sage = true
      else
        post.sage = false
      end
    end
    if post.valid? and errors.empty?
      post.save
      @ip_address['last_post'] = Time.now.to_i
      commit_picture post.id
      if op_post
        return "i#{post.id}"
      else
        @post = post
        return true
      end
    else
      remove_picture
      post.errors.each_value do |error|
        errors += error
      end
      return errors.join('<br />')
    end
  end

  def process_picture
    if params[:fpicture] or not params[:lpicture].empty?
      infa = {
        :exists   => false,
        :filename => Time.new.to_i.to_s + rand(9).to_s,
        :path     => "public/images/",
      }
      if params[:fpicture]
        infa.merge!({
          :tempfile => params[:fpicture].tempfile,
          :origin   => params[:fpicture].original_filename,
          :read     => params[:fpicture].tempfile.read,
          :size     => params[:fpicture].tempfile.size,
          :format   => params[:fpicture].content_type.split('/')[1]
        })
        infa[:hash] = MD5.hexdigest infa[:read]
        existing    = Picture.find_by_hash infa[:hash] 
        if existing
          infa.merge!({
            :exists   => true,
            :filename => existing.name,
            :format   => existing.format,
          })
        end
      else
        infa[:origin] = params[:lpicture]
        return [t('error.bad_url')] if not URL_REGEXP === infa[:origin]
        begin
          infa[:tempfile] = open "tmp/#{infa[:filename]}", 'wb'
          pending         = open infa[:origin], 'r', :read_timeout => 6
        rescue Timeout::Error
          infa[:tempfile].close; File.delete infa[:tempfile].path
          return [t('error.waiting')]
        rescue
          infa[:tempfile].close; File.delete infa[:tempfile].path
          return [t('error.bad_url')]
        else
          if pending.size > $settings[:picture_max_size]
            infa[:tempfile].close; File.delete infa[:tempfile].path
            return [t('error.pic_too_big')]
          end
          infa.merge!({
            :read   => pending.read,
            :size   => pending.size,
          })
          infa[:hash] = MD5.hexdigest infa[:read]
          existing    = Picture.find_by_hash infa[:hash]
          if existing
            infa.merge!({
              :exists   => true,
              :filename => existing.name,
              :format   => existing.format,
            })
          else
            infa[:tempfile].write infa[:read]
            begin
              test = ImageList.new infa[:tempfile].path
            rescue
              infa[:tempfile].close; File.delete infa[:tempfile].path
              return [t('error.pic_format')]
            else
              infa[:format] = test.format.downcase
            end
          end
        end
      end
      picture_record = Picture.new({
        :format   => infa[:format],
        :name     => infa[:filename],
        :size     => infa[:size],
        :origin   => infa[:origin],
        :hash     => infa[:hash],
      })
      if picture_record.valid?
        if not infa[:exists]
          infa[:path]     += "#{infa[:filename]}"
          thumbnail_path  = infa[:path] + 't'
          infa[:path]     += ".#{infa[:format]}"
          thumbnail_path  += ".#{infa[:format]}"
          FileUtils.copy  infa[:tempfile].path, infa[:path]
          thumbnail       = ImageList.new(infa[:path])[0]
          size            = $settings[:picture_max_pixels]
          if thumbnail.columns > size or thumbnail.rows > size
            thumbnail.resize_to_fit! size, size
          end
          thumbnail.write thumbnail_path
        end
        @picture_record = picture_record
        return true
      else
        errors = Array.new
        picture_record.errors.each_key do |error|
          errors += error
        end
        return errors
      end
    else
      return nil
    end
  end

  def commit_picture parent_id
    if @picture_record
      @picture_record.post_id = parent_id
      @picture_record.save
    end
  end

  def remove_picture
    if @picture_record
      path            = 'public' + @picture_record.path
      thumbnail_path  = 'public' + @picture_record.thumbnail_path
      File.delete path
      File.delete thumbnail_path
    end
  end
end