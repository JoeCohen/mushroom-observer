jQuery(document).ready(function () {
  // http://api.jquery.com/delegate/

  var $show_votes_container = jQuery('#show_votes_container');
  var $quality_vote_container = jQuery('#quality_vote_container');
  jQuery("body").delegate("[data-role='image_vote']", 'click', function(event){
    event.preventDefault();
    var data = $(this).data();
    image_vote(data.id, data.val);
  });

  function image_vote(id, value) {
    jQuery.ajax("/ajax/vote/image/" + id, {
      data: { value: value, authenticity_token: CSRF_TOKEN },
      dataType: 'text',
      async: true,
      error: function (response) {
        alert(response.responseText);
      },
      success: function(text) {
        var div = jQuery("#image_votes_" + id);
        div.html(text);
        // updates the side bar if on actual image page.
        if ($show_votes_container && $quality_vote_container) {
          $show_votes_container.load(window.location + " #show_votes_table");
          $quality_vote_container.load(window.location + " #quality_vote_content");
        }
      }
    });
  }
});

