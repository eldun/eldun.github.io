---
title: "Semi-Automating Microsoft Edge Searches"
subtitle:
use-math: true
layout: post
author: Evan
header-image: /assets\images\blog-images\automating-edge-searches\ms-rewards.jpg
header-image-alt: Microsoft Rewards medal.
header-image-title: Microsoft Rewards medal.
tags: web javascript automation
---
<script src="/js/post-scripts/automating-edge-searches/search.js" type="text/javascript"></script>

<a id="continue-reading-point"></a>
Microsoft has a suprisingly worthwhile rewards program - in addition to their three daily tasks (which range in value from 5 to 50 points each), there are a possible 250 points(~$1.25) to be earned from Bing searches within the Edge browser. This is my quick and dirty solution for snagging those points without manually searching 50 queries in Edge every day.
<!--end-excerpt-->

---
## Contents

<ul class="table-of-contents">
    <li><a href="#introduction">Introduction</a></li>
    <li><a href="#word-generation">Word Generation</a></li>
    <li><a href="#searching">Searching</a></li>
    <li><a href="#the-result">The Result</a></li>


</ul>
---

## <a id="introduction"></a>Introduction

First off, I'd like to say that I have nothing against Edge. It's beautiful and zippy. However, when I attempted to accrue search points naturally, I found myself cursing Bing's algorithm (StackOverflow on the second page?? GeeksForGeeks at the top?!??). And so here we are, automatically search made-up words in pursuit of the ultimate hypothetical prize:

![The ultimate hypothetical prize.](\assets\images\blog-images\automating-edge-searches\goal.png)

---

## <a id="word-generation"></a>Word Generation

The first order of business was generating plausible words. I'm not sure if Bing ignores nonsense words. In fact, I don't know if there's any critera that Bing filters by. Anyway, to generate words, I just sampled a bit of code from [here](https://j11y.io/javascript/random-word-generator/), which simply alternates vowels and consonants.

<pre><code class="language-javascript"> 

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

</code></pre>

<pre><code class="language-javascript">
console.log(createRandomWord(5));
console.log(createRandomWord(10));
console.log(createRandomWord(20));

Xajiq
Sexetelufa
Vazocolebaboxugosiqi
</code></pre>

---


## <a id="searching"></a>Searching


Well, we're almost done. Add the listener to the search button that's in the html:

<pre><code class="language-javascript"> 

document.addEventListener("DOMContentLoaded", init, false);
function init() {
  var button = document.getElementById("bing-search-button");
  button.addEventListener("click", startSearch, true);
}

</code></pre>

`startSearch` is called, and `continueSearch` is called recursively until the new tab is closed, or has reached the max number of searches (typically 50):

<pre><code class="language-javascript"> 

function startSearch() {
  let searchCount = 0;
  let randomWord = () => createRandomWord(Math.ceil(Math.random() * 14) + 3);
  let tab = window.open(`https://www.bing.com/search?q=${randomWord()}`);
  window.focus();
  setTimeout(continueSearch, 2000, searchCount);
  

  function continueSearch(searchCount) {
    if (searchCount < MAX_BING_SEARCHES && !tab.closed) {
      tab.location = `https://www.bing.com/search?q=${randomWord()}`;
      searchCount++;

      setTimeout(continueSearch, 5000, searchCount);
    }
  }
}
</code></pre>

---

## <a id="the-result"></a>The Result

I try to click this button everyday:

<button id="bing-search-button">Start Auto-Search</button>
