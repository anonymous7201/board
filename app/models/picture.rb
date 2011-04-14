class Picture < ActiveRecord::Base
	belongs_to :post
	
	validates_inclusion_of	:format, 	:in 			=> ['jpeg', 'png', 'gif']
	validates_length_of	:size,				:maximum 	=> $settings[:picture_max_size]

	def thumbnail_path
		"/images/#{self.name}t.#{self.format}"
	end

	def path
		"/images/#{self.name}.#{self.format}"
	end

	def exterminate
		self.delete_file
		self.delete
	end

	def delete_file
		File.delete 'public' + self.path
		File.delete 'public' + self.thumbnail_path
	end
end