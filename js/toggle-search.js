function toggleSearch() {
    var x = document.getElementById("search-container");

    if (x.style.visibility === "hidden") {
      x.style.visibility = "visible";
      document.getElementById("search-input").focus();

      document.onkeydown = function(evt) {
        evt = evt || window.event;
        if (evt.keyCode == 27 && x.style.visibility == "visible") {
          toggleSearch();
          return;
        }
    };

    } else {
      x.style.visibility = "hidden";
    }
  }