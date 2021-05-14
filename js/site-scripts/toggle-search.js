function toggleSearch() {
    var search_container = document.getElementById("search-container");
    var search_button = document.getElementById("search-button");
    var search_input = document.getElementById("search-input");
    var results_container = document.getElementById("results-container")


    if (search_container.style.visibility == "hidden") {
      search_container.style.visibility = "visible";
      search_input.value = "";
      results_container.style.visibility = "hidden";
      search_input.focus();

    search_input.oninput = handleInput;


      document.onkeydown = function(evt) {
        evt = evt || window.event;

        if (search_input.value == "") {
          results_container.style.visibility = "hidden";
        }
        else {
          results_container.style.visibility = "visible";
        }

        if (evt.keyCode == 27 && search_container.style.visibility == "visible") {
          toggleSearch();
          return;
        }

    };

    function handleInput(e) {
      if (search_input.value != "") {
        results_container.style.visibility = "visible";
      }
      else {
        results_container.style.visibility = "hidden";
      }
    }

    } else {
      search_container.style.visibility = "hidden";
    }

    // Styling
    if (search_container.style.visibility == "visible"){
      search_button.style.color = "#42cad1"
      search_container.style.display = "block";
      // search_input.focus();
    }
    else {
      search_button.style.color = "#cc773f";
      search_container.style.display = "none";
    }
  }
