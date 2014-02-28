(function(){
	'use strict';
	function set_style(name){
		$('#stylesheet').attr("href", "/css/" + name + ".css");
		localStorage.setItem("theme", name);
	}

	$( document ).ready(function() {
		var hiddenDiv = $(document.createElement('div'));

		hiddenDiv.addClass('hiddendiv common');

		$('body').append(hiddenDiv);

		$("textarea.autoresize").on('keyup', function () {
			var content = $(this).val();

			content = content.replace(/\n/g, '<br>');
			hiddenDiv.html(content + '<br class="lbr">');

			$(this).css('height', hiddenDiv.height()+23);
		});

		$('#theme_slate'   ).on('click', function () { set_style("slate"); });
		$('#theme_cerulean').on('click', function () { set_style("cerulean"); });
		$('#theme_cyborg'  ).on('click', function () { set_style("cyborg"); });
		$('#theme_cosmo'   ).on('click', function () { set_style("cosmo"); });
	});

	var theme = localStorage.getItem("theme");
	if(theme) {
		set_style(theme);
	}
})();
