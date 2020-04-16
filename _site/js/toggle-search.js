function toggleSearch() {
    console.log('inside toggleSearch');
    var x = document.getElementById("search-container");
    if (x.style.visibility === "hidden") {
      x.style.visibility = "visible";
    } else {
      console.log('x is not hidden. hiding...')
      x.style.visibility = "hidden";
    }
  }