var attach_suggestion_bindings;

function SuggestionModule(ids, url, text) {
  attach_suggestion_bindings = function () {
    var button = $("[data-role='suggest_names']");
    var whirly = " <span class='spinner-right mx-2'></span>";

    button.on('click', function (event) {
      button.attr("disabled", "disabled");
      var cover = $("<div class='cover'>").appendTo($(document.body));
      var progress = $("<div class='popup'>").appendTo($(document.body))
        .html(text.suggestions_processing_images + "..." + whirly)
        .css("padding", "1em 2em")
        .center()
        .show();

      var results = [];
      var any_worked = false;
      var predict = function (i) {
        progress.html(text.suggestions_processing_image + " " +
          (i + 1) + " / " + ids.length + "..." + whirly);
        $.ajax("https://images.mushroomobserver.org/model/predict", {
          method: "POST",
          data: { id: ids[i] },
          dataType: "text",
          async: true,
          complete: function (request) {
            if (request.status == 200) {
              results[i] = JSON.parse(request.responseText);
              any_worked = true;
            }
            if (i + 1 < ids.length) {
              predict(i + 1);
            } else if (any_worked) {
              progress.html(text.suggestions_processing_results + "..." +
                whirly);
              var out = JSON.stringify(results);
              url = url.replace("xxx", encodeURIComponent(out));
              if (event.ctrlKey)
                window.open(url, "_blank");
              else
                window.location.href = url;
            } else {
              alert(text.suggestions_error);
              progress.remove();
              cover.remove();
              button.attr("disabled", null);
            }
          }
        });
      };
      predict(0);
    });
  };

  $(document).ready(attach_suggestion_bindings);
}
