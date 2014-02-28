(function(){
	'use strict';

	$( document ).ready(function(){
		$('.jsform').on('click', 'input[type="submit"]', function(e){
			var form_data = new FormData(this.parentElement);
			var form = $(this).parent();
			var xhr = new XMLHttpRequest();
			xhr.open(form.attr('method'), form.attr('action'));
			xhr.onload = function() {
				$('#result').html(this.responseText);
			};
			xhr.onerror = function() {
				$('#result').html('Error!');
			};
			$('#result').html('Loading...');
			xhr.send(form_data);
			return false;
		});
	});
})();
