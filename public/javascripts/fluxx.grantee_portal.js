(function($){
  $.fn.extend({
		installFluxxDecorators: function() {
		  $.each($.fluxx.decorators, function(key,val) {
		    $(key).live.apply($(key), val);
		  });
		},
		loadTable: function($table, pageIncrement) {
			$table.attr('data-src', $table.attr('data-src').replace(/page=(\d)+/, function(a,b){
				var page = parseInt(b) + pageIncrement;
			  return 'page=' + page;
			}));
			$.ajax({
        url: $table.attr('data-src'),
				success: function(data, status, xhr){
					$table.html(data);
        }
      });
		}
	});
	
	$.extend(true, {
		fluxx: {
			decorators: {
	      'a.prev-page': [
	        'click', function(e) {          
						e.preventDefault();
						var $elem = $(this);
						if ($elem.hasClass('disabled'))
							return;
						var $area = $elem.parents('.content');
						$.fn.loadTable($area, -1);
	        }
	      ],
	      'a.next-page': [
	        'click', function(e) {          
						e.preventDefault();
						var $elem = $(this);
						if ($elem.hasClass('disabled'))
							return;						
						var $area = $elem.parents('.content');
						$.fn.loadTable($area, 1);
	        }
	      ]
			}
		}
	});
})(jQuery);

$(document).ready(function() {
	$.fn.installFluxxDecorators();
});
