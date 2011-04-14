var RecaptchaOptions = {
	theme: 'custom',
	custom_theme_widget: 'recaptcha_widget'
}

var preview_options = {
	fixed: true,
	content: 'загрузка...',
	showTime: 200,
	hideTime: 200,
	onShow: function() {
		link = this.getParent();
		link = $(link.html());
		id = link.attr('href').substring(1);
		post = $('#' + id);
		if (post.html() == null) {
			// аякса пока что не будет
			result = 'пост не найден.';
			this.getTooltip().html(result);
		}
		else {
			// post = post.children();
			result = $(post.html());
			result.css('max-width', '750px');
			result.children().css('max-width', '750px');
			result.find('.header').css('opacity', '1');
			result.find('.reply_link').remove();
			tooltip = $(this.getTooltip());
			tooltip.html(result);
		}
	},
	onHide: function() {
		// this.getTooltip().html('загрузка...');
	}
}



$(document).ready(function() {
	h_post = null;
	file_shown = false;
	form_moved = false;
	show_replies = 'all';

	$('#thread_button').click(toggle_thread_form);
	$('.post_container').hover(post_hover, post_unhover);
	$('#file label').click(toggle_file);
	$('#thread_form').submit(submit_thread);
	$('.reply_link').click(move_reply_form);
	$('#file_switch').click(loltoggle_file);
	$('#reply_form').submit(submit_reply);
	$('#reply_form #message').bind('keydown', 'ctrl+return', submit_reply);
	$('.comment_link').click(add_comment_link);
	$('.up_link').click(goto_post);
	$('.post_link').simpletip(preview_options); //я не могу в джаваскрипт

	// ололо я идиот
	$('#editbox b').click(bold);
	$('#editbox i').click(italic);
	$('#editbox u').click(underline);
	$('#editbox .spoiler').click(spoiler);
	$('#editbox a').click(link);
});



function preview_show() {
	link = $(this);
	id = link.attr('href').substring(1);
	post = $('#' + id);
	popup = $("<div id='popup' class='post'>загрузка...</div>");
	link.simpletip({
		fixed: true,
	});
}

function preview_hide() {
	$('#popup').remove();
}

function goto_post() {
	$($(this).attr('href')).css('display', 'block');
}

function add_comment_link() {
	textarea = $('#message');
	textarea.val(textarea.val() + '>>' + $(this).html().substring(1) + ' ');
	return false;
}

function loltoggle_replies() {
	if (show_replies == 'all') {
		show_new_replies();
	} else {
		show_all_replies();
	}
	return false;
}

function show_new_replies() {
	if (new_replies > 0) {
		show_replies = 'new';
		span = $('#replies');
		span.find('b').html('только новые');
		span.find('p').html('(' + new_replies + ' из ' + all_replies + ')');
		span.find('a').html('Показать все')
		$('.post').parent().css('display', 'none');
		$('.new').parent().css('display', 'block');
	}
}

function show_all_replies() {
		show_replies = 'all';
		span = $('#replies');
		span.find('b').html('все');
		span.find('p').html('(' + new_replies + ')');
		span.find('a').html('Показать новые')
		$('.post').parent().css('display', 'block');
}

function bold() {
	replace_shit('**', '**');
}
function italic() {
	replace_shit('*', '*');
}
function underline() {
	replace_shit('__', '__');
}
function spoiler() {
	replace_shit('%%', '%%');
}
function link() {
	href = prompt('Адрес ссылки:');
	if (href.length > 0) {
		replace_shit('<a href="' + href + '">', '</a>');
	}
}

function replace_shit(opening, ending) {
	textarea = $('#message');
	initial_value = textarea.val();
	selection = textarea.getSelection()
	left = initial_value.substring(0, selection.start);
	right = initial_value.substring(selection.end, initial_value.length);
	textarea.val(left + opening + selection.text);
	textarea.val(textarea.val() + ending + right);
	caret = selection.end + opening.length
	textarea.focus().caret(caret, caret);
}


function set_caret_to_pos (input, pos) {
  setSelectionRange(input, pos, pos);
}



function clear_form() {
	hide_file();
	$('#reply_form').find('textarea').val('');
	$('#errors').html('');
	$('#idd').val($('#thread').attr('class'));
}

function submit_reply() {
	form = $('#reply_form');
	container = $('#reply_form_container');
	button = form.find('#submitt');
	errors = form.find('#errors');

	form.ajaxSubmit({
		beforeSubmit: function() {
			form.css('opacity', '0.5');
			form.find('input').blur();
			form.find('textarea').blur();
			button.attr('disabled', true);
		},
		success: function(reply) {
			form.css('opacity', '1');
			button.attr('disabled', false);
			if (reply == 'ban') {
				window.location = '/banned/'	
			}	else if (reply.substring(0, 1) == '<') {
				post = $(reply);
				$('#thread').append(post);
				$('#thread').after(container);
				$.scrollTo(post, 10);
				$('.post_container').unbind().hover(post_hover, post_unhover);
				$('.reply_link').unbind().click(move_reply_form);
				clear_form();
			} else {
				errors.html(reply);
			}
		},
		error: alert_error
	});
	return false;
}

function loltoggle_file() {
	if (file_shown) {
		hide_file();
	} else {
		show_file();
	}
}

function show_file() {
	file = $('#reply_form #file');
	$('#file_switch').html('картинка:')
	file.find('input').css('display', 'inline');
	file.find('label').css('display', 'inline');
	file.find('#lpicture').css('display', 'none')
	file_shown = true;
}


function hide_file() {
	file = $('#reply_form #file');
	$('#file_switch').html('приложить картинку')
	file.find('input').css('display', 'none');
	file.find('#lpicture').val('');
	file.find('#fpicture').val('');
	file.find('#ffpicture').attr('checked', true)
	file.find('#flpicture').attr('checked', false)
	file.find('label').css('display', 'none');
	file_shown = false;
}

function move_reply_form() {
	form_moved = true;
	form = $('#reply_form_container');
	post = $(this).parent().parent().parent();
	$.scrollTo(post, 10, settings={offset:{top:-200}})
	post.after(form);
	id = post.attr('id')
	form.find('#idd').val(id);
	textarea = form.find('textarea');
	textarea.focus();
	textarea.val(textarea.val() + '>>' + id + ' ');
	return false;
}

function post_hover() {
	if (h_post != null) {
		$('#' + h_post).find('.header').css('opacity', '0');
	}
	$(this).find('.header').css('opacity', '1');
	h_post = $(this).attr('id');
}

function post_unhover() {
	h_post = null;
	$(this).find('.header').css('opacity', '0');
}

function toggle_file() {
	input = $(this).find('input').attr('id').substring(1);
	$('#' + input).focus().css('display', 'block');
	if (input == 'lpicture') {
		$('#fpicture').css('display', 'none');
	}
	else {
		$('#lpicture').css('display', 'none');
	}
}

function toggle_thread_form() {
	button = $('#thread_button');
	form = $('#thread_form_wrapper');
	if (button.hasClass('active')) {
		button.removeClass('active');
		form.css('display', 'none');
	} else {
		button.addClass('active');
		form.css('display', 'block');
		form.find('textarea').focus();
	}
}


function do_nothing() {
	// hui pizda
}

function submit_thread() {
	form = $(this);
	button = $('#submitt');
	errors = $('#errors');
	form.ajaxSubmit({
		beforeSubmit: function() {
			form.css('opacity', '0.4');
			form.find('input').blur();
			button.attr('disabled', 'disabled');
			errors.html('');
		},
		success: function(reply) {
			if (reply == 'ban') {
				window.location = '/banned/'	
			}	else if (reply.substring(0, 1) == 'i') {
				window.location = '/thread/' + reply.substring(1);
			} else {
				form.css('opacity', '1');
				button.removeAttr('disabled');
				errors.html(reply);
			}
		},
		error: alert_error,
	});
	return false;
}

function alert_error() {
	alert('Что-то пошло не так.' +
					'Либо на сервере проблемы, либо у вас с соединением.')
}

