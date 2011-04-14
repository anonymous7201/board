class Post < ActiveRecord::Base
  include ApplicationHelper
  has_one     :picture

  before_create do
    post_ids = Array.new
    counter = 0
    self.message = parse self.message
    self.message.gsub! /##(\d+)/ do |id|
      result = ''
      counter += 1
      if counter < 11
        begin
          id = id[2..id.length]
          post = Post.find id.to_i
        rescue ActiveRecord::RecordNotFound
          ''
        else
          if post.author == self.author
            url = "##{post.id}"
            result = "<a class='prooflink' href='#{url}'>"
            result += "###{post.id}</a>"
          end
          result
        end
      end
    end
    if self.root? 
      self.bump     = Time.now
      self.replies  = 0
    else
      root          = self.root
      root.bump     = Time.now if not self.sage
      root.replies  += 1
      root.save
    end
  end

  def self.get_page page_number
    Post.where(:parent_id => nil)
        .order('bump DESC')
        .includes(:picture)
        .paginate(:per_page => $settings[:per_page], :page => page_number)
  end

  def get_replies
    Post.where(:parent_id => self.id).includes(:picture).order('number ASC')
  end

  def root?
    self.parent_id == nil
  end

  def root
    Post.find self.parent_id
  end

  def exterminate 
    if self.root?
      post_ids    = Array.new
      picture_ids = Array.new
      Post.where(:parent_id => self.id).includes(:picture).each do |post|
        post_ids    << post.id
        if post.picture
          post.picture.delete_file
          picture_ids << post.picture.id
        end
      end
      Post.delete     post_ids
      Picture.delete  picture_ids
    end
    self.picture.exterminate if self.picture
    self.delete
    if not self.root?
      root = self.root
      root.replies -= 1
      root.bump = root.get_replies.last.created_at
      root.save
    end
  end
end