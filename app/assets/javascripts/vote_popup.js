function VotePopupModule(showNamingsLostChangesText) {
  $(document).ready(function () {

    var _haveVotesChanged = false;
    var _haveVotesBeenSaved = false;

    var save_votes_button = function () {
      return $("[data-role='save_votes']");
    };

    var close_popup_buttons = function () {
      return $("[data-role='close_popup']");
    };

    var open_popup_buttons = function () {
      return $("[data-role='open_popup']");
    };

    var change_vote_selects = function () {
      return $("[data-role='change_vote']");
    };

    var vote_popups = function () {
      return $("[data-role='popup']");
    };

    var attach_bindings = function () {
      close_popup_buttons().click(function () {
        $(this).parents(".popup").first().hide();
      });

      open_popup_buttons().click(function (event) {
        event.preventDefault();
        console.log(event);
        var namingId = $(this).data("id");
        vote_popups().hide();
        $("#show_votes_" + namingId)
          .center().show();
      });

      change_vote_selects().change(function (event) {
        var _this = $(this);
        var value = _this.val();
        var naming_id = _this.data("id");
        _haveVotesChanged = true;

        // If setting vote to 3.0, go through all the rest and downgrade any
        // old 3.0's to 2.0.  Only one 3.0 vote is allowed. Also disable all
        // the menus while the AJAX request is pending.
        if (value == "3.0") {
          change_vote_selects().each(function () {
            var _this2 = $(this);
            if (_this2.data("id") != naming_id && _this2.val() == "3.0") {
              _this2.val("2.0");
            }
            _this2.attr("disabled", "disabled");
          });
        }

        $.ajax("/ajax/vote/naming/" + naming_id, {
          data: {value: value, authenticity_token: csrf_token()},
          dataType: "text",
          async: true,
          complete: function (request) {
            _haveVotesChanged = false;
            if (request.status == 200) {
              var html  = $(request.responseText);
              var title = html.children().eq(0);
              var div   = html.children().eq(1);
              document.title = title.attr("title");
              $("#title-caption").html(title.html());
              $("#naming_partial").html(div.html());
              attach_bindings();
            } else {
              change_vote_selects().each(function () {
                $(this).val($(this).data("old_value"))
                       .attr("disabled", null);
              });
              alert(request.responseText);
            }
          }
        });

        // TODO: Popup a whirly to make it clear something is happening.
      });

      // Save initial value in case of error, when we'll need to revert.
      change_vote_selects().each(function (event) {
        $(this).data("old_value", $(this).val());
      });
    };

    // Alert the user if they haven't saved data.
    window.onbeforeunload = function () {
      if (_haveVotesChanged && !_haveVotesBeenSaved)
        return showNamingsLostChangesText;
    }

    attach_bindings();

    // Don't need this if AJAX available.
    save_votes_button().hide();
  });
}
