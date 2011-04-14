Board::Application.routes.draw do
	root :to => 'posts#index'

	match 'page/:number'			=> 'posts#index'
	match 'thread/:id'				=> 'posts#view'
	match 'thread/:id/reply'	=> 'posts#reply'
	match 'write'							=> 'posts#create'
	match 'post/:id'					=> 'posts#get_post'

	match 'throne'									=> 'admin#index'		
	match 'throne/post/:id'					=> 'admin#post'
	match 'throne/post/:id/delete'	=> 'admin#delete'
	match 'throne/post/:id/update'	=> 'admin#update'
	match 'throne/login'						=> 'admin#login'
	match 'throne/logout'						=> 'admin#logout'
	match 'throne/captcha'					=> 'admin#toggle_captcha'

	match 'banned'	=> 'application#banned'
	match '*path' 	=> 'application#not_found_action'
end
