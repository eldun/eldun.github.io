// const MICROSOFT_EDGE_PATH =
//   "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

const MAX_BING_SEARCHES = 50;

// From https://j11y.io/javascript/random-word-generator/
function createRandomWord(length) {
  var consonants = "bcdfghjklmnpqrstvwxyz",
    vowels = "aeiou",
    rand = function (limit) {
      return Math.floor(Math.random() * limit);
    },
    i,
    word = "",
    length = parseInt(length, 10),
    consonants = consonants.split(""),
    vowels = vowels.split("");
  for (i = 0; i < length / 2; i++) {
    var randConsonant = consonants[rand(consonants.length)],
      randVowel = vowels[rand(vowels.length)];
    word += i === 0 ? randConsonant.toUpperCase() : randConsonant;
    word += i * 2 < length - 1 ? randVowel : "";
  }
  return word;
}

// function launchProgram(exe, callback) {
//   const execFile = require("child_process").execFile;
//   const child = execFile(exe, (err, stdout, stderr) => {
//     if (err) {
//       throw err;
//     }
//   });
//   callback(child);
// }

function startSearch() {
  console.log("start search");
  let searchCount = 0;
  let randomWord = () => createRandomWord(Math.ceil(Math.random() * 7) + 3);
  let tab = window.open(`https://www.bing.com/search?q=${randomWord()}`);
  window.focus();
  setTimeout(continueSearch, 2000, searchCount);
  

  function continueSearch(searchCount) {
    console.log("continue search");
    if (searchCount < MAX_BING_SEARCHES && !tab.closed) {
      tab.location = `https://www.bing.com/search?q=${randomWord()}`;
      searchCount++;

      setTimeout(continueSearch, (Math.random()*3)+6000, searchCount);    }
  }
}

document.addEventListener("DOMContentLoaded", init, false);
function init() {
  var button = document.getElementById("bing-search-button");
  button.addEventListener("click", startSearch, true);
}
