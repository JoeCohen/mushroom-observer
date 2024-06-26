$(document).ready(function () {
  var zoom = 1.0;
  var expanded = false;
  var container = jQuery(".thumbnail-map-container");
  var map = jQuery(".thumbnail-map");

  // Maximum amount to allow zoom, otherwise it's easy to zoom so far in it
  // becomes a featureless blur.  No harm, just sort of annoying.
  var MAX_ZOOM = 50.0;

  function reset_map() {
    container.css({ width: "", height: "", overflow: "" });
    map.css({ top: "", left: "", width: "", height: "" });
    zoom = 1.0;
  }

  function zoom_map(dir) {
    if (dir > 0) zoom *= Math.sqrt(2);
    if (dir < 0) zoom /= Math.sqrt(2);
    if (zoom <= 1.0) {
      reset_map();
    } else {
      if (zoom > MAX_ZOOM) zoom = MAX_ZOOM;
      do_zoom();
      load_larger_map();
    }
  }

  function do_zoom() {
    var cw = container.width();
    var ch = container.height();
    var mw = Math.round(cw * zoom);
    var mh = Math.round(ch * zoom);
    var f = 1.0 / Math.sqrt(zoom);
    var x = Math.round(THUMBNAIL_MAP_X / 100 * (mw - cw * f) - cw / 2 * (1 - f));
    var y = Math.round(THUMBNAIL_MAP_Y / 100 * (mh - ch * f) - ch / 2 * (1 - f));
    container.css({
      width: cw + "px",
      height: ch + "px",
      overflow: "hidden"
    });
    map.css({
      top: -y + "px",
      left: -x + "px",
      width: mw + "px",
      height: mh + "px"
    });
  }

  function load_larger_map() {
    if (expanded) return
    var large = jQuery("<img/>");
    var url = jQuery("#globe_image").data("globe-large-url");
    large.attr("src", url).on('load', function () {
      map.find(">img").attr("src", url);
    });
    expanded = true;
  }

  function cancel(event) {
    event.stopPropagation();
    return false;
  }

  jQuery(window).resize(reset_map);

  container.on("wheel", function (event) {
    if (event.ctrlKey) {
      if (THUMBNAIL_MAP_ON)
        zoom_map(event.originalEvent.deltaY < 0 ? 1 : -1);
      return cancel(event);
    }
  });

  container.on('click', function () { window.location = THUMBNAIL_MAP_LINK });

  container.find(".plus-button").on('click', function (event) {
    zoom_map(1);
    return cancel(event);
  });

  container.find(".minus-button").on('click', function (event) {
    zoom_map(-1);
    return cancel(event);
  });

  container.find(".thumbnail-buttons").click(cancel);
  container.find(".plus-button,.minus-button,.thumbnail-buttons")
    .dblclick(cancel).mousedown(cancel).mouseup(cancel);
});
