function toggleSearch() {
    var x = document.getElementById("search-container");
    var y = document.getElementById("search-button");
    var z = document.getElementById("search-input");


    if (x.style.visibility == "hidden") {
      x.style.visibility = "visible";
      z.focus();

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

    if (x.style.visibility == "visible"){
      y.style.color = "#42cad1"
      x.style.display = "block";
      z.focus();
    }
    else {
      y.style.color = "#cc773f";
      x.style.display = "none";
    }
  }