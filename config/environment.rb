# Load the rails application
require File.expand_path('../application', __FILE__)
require 'RMagick'
require 'net/http'
require 'uri'
require 'open-uri'

REDIS 		= Redis.new
SALT			= 'porole'
RCC_PUB 	= '6LfY_8ESAAAAAAo47-7wrsQN6UVyYxZDLpi3N2v4'
RCC_PRIV 	= '6LfY_8ESAAAAAHrd3E0koSABF_OhUrA819mC24O8'
URL_REGEXP = /(http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\/~\+#])?/

$settings 	= {
	:per_page 					=> 10,
	:picture_max_pixels => 200,
	:picture_max_size		=> 6500000,
	:captcha						=> false,
}

$admin_passwords = [
	'46287f539c3759bd91db84ceac7a668a', # R
]

Haml::Template.options[:format] = :xhtml
Haml::Template.options[:ugly] 	= true

# Initialize the rails application
Board::Application.initialize!
