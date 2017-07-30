window.CrystalDoc = (window.CrystalDoc || {});

CrystalDoc.base_path = (CrystalDoc.base_path || "");

CrystalDoc.searchIndex = (CrystalDoc.searchIndex || false);
CrystalDoc.MAX_RESULTS_DISPLAY = 140;

CrystalDoc.runQuery = function(query) {
  function searchType(type, query, results) {
    var matches = [];
    var matchedFields = [];
    var name = type.full_name;
    var i = name.lastIndexOf("::");
    if (i > 0) {
      name = name.substring(i + 2);
    }
    var nameMatches = query.matches(name);
    if (nameMatches){
      matches = matches.concat(nameMatches);
      matchedFields.push("name");
    }

    var namespaceMatches = query.matchesNamespace(type.full_name);
    if(namespaceMatches){
      matches = matches.concat(namespaceMatches);
      matchedFields.push("name");
    }

    var docMatches = query.matches(type.doc);
    if(docMatches){
      matches = matches.concat(docMatches);
      matchedFields.push("doc");
    }
    if (matches.length > 0) {
      results.push({
        id: type.id,
        result_type: "type",
        kind: type.kind,
        name: name,
        full_name: type.full_name,
        href: type.path,
        summary: type.summary,
        matched_fields: matchedFields,
        matched_terms: matches
      });
    }

    searchMethods(type.instance_methods, type, "instance_method", query, results);
    searchMethods(type.class_methods, type, "class_method", query, results);
    searchMethods(type.macros, type, "macro", query, results);
    type.constants.forEach(function(constant){
      searchConstant(constant, type, query, results);
    });

    type.types.forEach(function(subtype){
      searchType(subtype, query, results);
    });
  };

  function searchMethods(methods, type, kind, query, results) {
    methods.forEach(function (method) {
      searchMethod(method, type, kind, query, results);
    });
  }

  function searchMethod(method, type, kind, query, results) {
    var matches = [];
    var matchedFields = [];
    var nameMatches = query.matchesMethod(method.name, kind, type);
    if (nameMatches){
      matches = matches.concat(nameMatches);
      matchedFields.push("name");
    }

    method.args.forEach(function(arg){
      var argMatches = query.matches(arg.external_name);
      if (argMatches) {
        matches = matches.concat(argMatches);
        matchedFields.push("args");
      }
    });

    var docMatches = query.matches(type.doc);
    if(docMatches){
      matches = matches.concat(docMatches);
      matchedFields.push("doc");
    }

    if (matches.length > 0) {
      var typeMatches = query.matches(type.full_name);
      if (typeMatches) {
        matchedFields.push("type");
        matches = matches.concat(typeMatches);
      }
      results.push({
        id: method.id,
        type: type.full_name,
        result_type: kind,
        name: method.name,
        full_name: type.full_name + "#" + method.name,
        args_string: method.args_string,
        summary: method.summary,
        href: type.path + "#" + method.id,
        matched_fields: matchedFields,
        matched_terms: matches
      });
    }
  }

  function searchConstant(constant, type, query, results) {
    var matches = [];
    var matchedFields = [];
    var nameMatches = query.matches(constant.name);
    if (nameMatches){
      matches = matches.concat(nameMatches);
      matchedFields.push("name");
    }
    var docMatches = query.matches(constant.doc);
    if(docMatches){
      matches = matches.concat(docMatches);
      matchedFields.push("doc");
    }
    if (matches.length > 0) {
      var typeMatches = query.matches(type.full_name);
      if (typeMatches) {
        matchedFields.push("type");
        matches = matches.concat(typeMatches);
      }
      results.push({
        id: constant.id,
        type: type.full_name,
        result_type: "constant",
        name: constant.name,
        full_name: type.full_name + "#" + constant.name,
        value: constant.value,
        summary: constant.summary,
        href: type.path + "#" + constant.id,
        matched_fields: matchedFields,
        matched_terms: matches
      });
    }
  }

  var results = [];
  searchType(CrystalDoc.searchIndex.program, query, results);
  return results;
};

CrystalDoc.rankResults = function(results, query) {
  function uniqueArray(ar) {
    var j = {};

    ar.forEach(function(v) {
      j[v + "::" + typeof v] = v;
    });

    return Object.keys(j).map(function(v) {
      return j[v];
    });
  }

  results = results.sort(function(a, b) {
    var matchedTermsDiff = uniqueArray(b.matched_terms).length - uniqueArray(a.matched_terms).length;
    var aHasDocs = b.matched_fields.includes("doc");
    var bHasDocs = b.matched_fields.includes("doc");

    if (matchedTermsDiff != 0 || (aHasDocs != bHasDocs)) {
      if(CrystalDoc.DEBUG) { console.log("matchedTermsDiff: " + matchedTermsDiff, aHasDocs, bHasDocs); }
      return matchedTermsDiff;
    }

    var aOnlyDocs = aHasDocs && a.matched_fields.length == 1;
    var bOnlyDocs = bHasDocs && b.matched_fields.length == 1;

    if (a.result_type == "type" && b.result_type != "type" && !aOnlyDocs) {
      if(CrystalDoc.DEBUG) { console.log("a is type b not"); }
      return -1;
    } else if (b.result_type == "type" && a.result_type != "type" && !bOnlyDocs) {
      if(CrystalDoc.DEBUG) { console.log("b is type, a not"); }
      return 1;
    }
    if (a.matched_fields.includes("name")) {
      if (b.matched_fields.includes("name")) {
        var a_name = CrystalDoc.prefixForType(a.result_type) + a.result_type == "type" ? a.full_name : a.name;
        var b_name = CrystalDoc.prefixForType(b.result_type) + b.result_type == "type" ? b.full_name : b.name;
        for(var i = 0; i < query.terms.length; i++) {
          var term = query.terms[i];
          var a_orig_index = a_name.indexOf(term);
          var b_orig_index = b_name.indexOf(term);
          if(CrystalDoc.DEBUG) { console.log(a_orig_index, b_orig_index, a_orig_index - b_orig_index); }
          if (a_orig_index >= 0) {
            if (b_orig_index >= 0) {
              if(CrystalDoc.DEBUG) { console.log("both have exact match", a_orig_index > b_orig_index ? -1 : 1); }
              if(a_orig_index != b_orig_index) {
                if(CrystalDoc.DEBUG) { console.log("both have exact match at different positions", a_orig_index > b_orig_index ? 1 : -1); }
                return a_orig_index > b_orig_index ? 1 : -1;
              }
            } else {
              if(CrystalDoc.DEBUG) { console.log("a has exact match, b not"); }
              return -1;
            }
          } else if (b_orig_index >= 0) {
            if(CrystalDoc.DEBUG) { console.log("b has exact match, a not"); }
            return 1;
          }
        }
      } else {
        if(CrystalDoc.DEBUG) { console.log("a has match in name, b not"); }
        return -1;
      }
    } else if (
      !a.matched_fields.includes("name") &&
      b.matched_fields.includes("name")
    ) {
      return 1;
    }

    var matchedFieldsDiff = b.matched_fields.length - a.matched_fields.length;
    if(CrystalDoc.DEBUG) { console.log(matchedFieldsDiff); }
    if (matchedFieldsDiff != 0) {
      return matchedFieldsDiff;
    }

    return a.name.localeCompare(b.name);
  });

  if (results.length > 1) {
    // if we have more than two search terms, only include results whith the most matches
    var bestMatchedTerms = uniqueArray(results[0].matched_terms).length;

    results = results.filter(function(result) {
      return uniqueArray(result.matched_terms).length + 1 >= bestMatchedTerms;
    });
  }
  return results;
};

CrystalDoc.prefixForType = function(type) {
  switch (type) {
    case "instance_method":
      return "#";

    case "class_method":
    case "macro":
      return ".";

    default:
      return false;
  }
};

CrystalDoc.displaySearchResults = function(results, query) {
  function sanitize(html){
    return html.replace(/<(?!\/?code)[^>]+>/g, "");
  }

  // limit results
  if (results.length > CrystalDoc.MAX_RESULTS_DISPLAY) {
    results = results.slice(0, CrystalDoc.MAX_RESULTS_DISPLAY);
  }

  var $frag = document.createDocumentFragment();
  var $resultsElem = document.querySelector(".search-list");
  $resultsElem.innerHTML = "<!--" + JSON.stringify(query) + "-->";

  results.forEach(function(result, i) {
    var url = CrystalDoc.base_path + result.href;
    var type = false;

    var title = query.highlight(result.result_type == "type" ? result.full_name : result.name);

    var prefix = CrystalDoc.prefixForType(result.result_type);
    if (prefix) {
      title = "<b>" + prefix + "</b>" + title;
    }

    title = "<strong>" + title + "</strong>";

    if (result.args_string) {
      title +=
        "<span class=\"args\">" + query.highlight(result.args_string) + "</span>";
    }

    $elem = document.createElement("li");
    $elem.className = "search-result search-result--" + result.result_type;
    $elem.dataset.href = url;
    $elem.setAttribute("title", result.full_name + " docs page");

    var $title = document.createElement("div");
    $title.setAttribute("class", "search-result__title");
    var $titleLink = document.createElement("a");
    $titleLink.setAttribute("href", url);

    $titleLink.innerHTML = title;
    $title.appendChild($titleLink);
    $elem.appendChild($title);
    $elem.addEventListener("click", function() {
      $titleLink.click();
    });

    if (result.result_type !== "type") {
      var $type = document.createElement("div");
      $type.setAttribute("class", "search-result__type");
      $type.innerHTML = query.highlight(result.type);
      $elem.appendChild($type);
    }

    if(result.summary){
      var $doc = document.createElement("div");
      $doc.setAttribute("class", "search-result__doc");
      $doc.innerHTML = query.highlight(sanitize(result.summary));
      $elem.appendChild($doc);
    }

    $elem.appendChild(document.createComment(JSON.stringify(result)));
    $frag.appendChild($elem);
  });

  $resultsElem.appendChild($frag);

  CrystalDoc.toggleResultsList(true);
};

CrystalDoc.toggleResultsList = function(visible) {
  if (visible) {
    document.querySelector(".types-list").classList.add("hidden");
    document.querySelector(".search-results").classList.remove("hidden");
  } else {
    document.querySelector(".types-list").classList.remove("hidden");
    document.querySelector(".search-results").classList.add("hidden");
  }
};

CrystalDoc.Query = function(string) {
  this.original = string;
  this.terms = string.split(/\s+/).filter(function(word) {
    switch (word[0]) {
      case "#":
      case ".":
        return word.length > 1;

      default:
        return word.length > 0;
    }
  });

  var normalized = this.terms.map(CrystalDoc.Query.normalizeTerm);
  this.normalized = normalized;

  function runMatcher(field, matcher) {
    if (!field) {
      return false;
    }
    var normalizedValue = CrystalDoc.Query.normalizeTerm(field);

    var matches = [];
    normalized.forEach(function(term) {
      if (matcher(normalizedValue, term)) {
        matches.push(term);
      }
    });
    return matches.length > 0 ? matches : false;
  }

  this.matches = function(field) {
    return runMatcher(field, function(normalized, term) {
      if (term[0] == "#" || term[0] == ".") {
        return false;
      }
      return normalized.indexOf(term) >= 0;
    });
  };

  function namespaceMatcher(normalized, term){
    var i = term.indexOf(":");
    if(i >= 0){
      while(term[0] == ":") { term = term.substring(1); }
      //while(term[term.length-1] == ":") { term = term.substring(0, term.length-1); }
      return normalized.indexOf(term) >= 0;
    }
    return false;
  }
  this.matchesMethod = function(name, kind, type) {
    return runMatcher(name, function(normalized, term) {
      var i = term.indexOf("#");
      if(i >= 0){
        if (kind != "instance_method") {
          return false;
        }
      }else{
        i = term.indexOf(".");
        if(i >= 0){
          if (kind != "class_method" && kind != "macro") {
            return false;
          }
        }else{
          //neither # nor .
          if(term.indexOf(":") && namespaceMatcher(normalized, term)){
            return true;
          }
        }
      }

      var methodName = term;
      if(i >= 0){
        var termType = term.substring(0, i);
        methodName = term.substring(i+1);

        if(termType != "") {
          if(CrystalDoc.Query.normalizeTerm(type.full_name).indexOf(termType) < 0){
            return false;
          }
        }
      }
      return normalized.indexOf(methodName) >= 0;
    });
  };

  this.matchesNamespace = function(namespace){
    return runMatcher(namespace, namespaceMatcher);
  };

  this.highlight = function(string) {
    if (typeof string == "undefined") {
      return "";
    }
    function escapeRegExp(s) {
      return s.replace(/[.*+?\^${}()|\[\]\\]/g, "\\$&");
    }
    return string.replace(
      new RegExp("(" + this.normalized.map(escapeRegExp).join("|") + ")", "gi"),
      "<mark>$1</mark>"
    );
  };
};
CrystalDoc.Query.normalizeTerm = function(term) {
  if(!term.toLowerCase){
    console.log(term)
  }
  return term.toLowerCase();
};

CrystalDoc.search = function(string) {
  if(!CrystalDoc.searchIndex) {
    console.error("CrystalDoc search index not initialized.");
    return;
  }
  var query = new CrystalDoc.Query(string);
  var results = CrystalDoc.runQuery(query);
  results = CrystalDoc.rankResults(results, query);
  CrystalDoc.displaySearchResults(results, query);
};

CrystalDoc.initializeIndex = function(data) {
  CrystalDoc.searchIndex = data;

  document.dispatchEvent(new Event("CrystalDoc:loaded"));
};

CrystalDoc.loadIndex = function() {
  function loadJSON(file, callback) {
    var xobj = new XMLHttpRequest();
    xobj.overrideMimeType("application/json");
    xobj.open("GET", file, true);
    xobj.onreadystatechange = function() {
      if (xobj.readyState == 4 && xobj.status == "200") {
        callback(xobj.responseText);
      }
    };
    xobj.send(null);
  }

  function loadScript(file) {
    script = document.createElement("script");
    script.src = file;
    document.body.appendChild(script);
  }

  function parseJSON(json) {
    CrystalDoc.initializeIndex(JSON.parse(json));
  }

  for(var i = 0; i < document.scripts.length; i++){
    var script = document.scripts[i];
    if (script.src && script.src.indexOf("js/doc.js") >= 0) {
      if (script.src.indexOf("file://") == 0) {
        // We need to support JSONP files for the search to work on local file system.
        var jsonPath = script.src.replace("js/doc.js", "index.jsonp");
        loadScript(jsonPath);
        return;
      } else {
        var jsonPath = script.src.replace("js/doc.js", "index.json");
        loadJSON(jsonPath, parseJSON);
        return;
      }
    }
  }
  console.error("Could not find location of js/search.js");
};

// Callback for jsonp
function crystal_doc_search_index_callback(data) {
  CrystalDoc.initializeIndex(data);
}


document.addEventListener('DOMContentLoaded', function() {
  var sessionStorage;
  try {
    sessionStorage = window.sessionStorage;
  } catch (e) { }
  if(!sessionStorage) {
    sessionStorage = {
      setItem: function() {},
      getItem: function() {},
      removeItem: function() {}
    };
  }

  var repositoryName = document.querySelector('#repository-name').getAttribute('content');
  var typesList = document.querySelector('.types-list');
  var searchInput = document.querySelector('.search-input');
  var parents = document.querySelectorAll('.types-list li.parent');

  for(var i = 0; i < parents.length; i++) {
    var _parent = parents[i];
    _parent.addEventListener('click', function(e) {
      e.stopPropagation();

      if(e.target.tagName.toLowerCase() == 'li') {
        if(e.target.className.match(/open/)) {
          sessionStorage.removeItem(e.target.getAttribute('data-id'));
          e.target.className = e.target.className.replace(/ +open/g, '');
        } else {
          sessionStorage.setItem(e.target.getAttribute('data-id'), '1');
          if(e.target.className.indexOf('open') == -1) {
            e.target.className += ' open';
          }
        }
      }
    });

    if(sessionStorage.getItem(_parent.getAttribute('data-id')) == '1') {
      _parent.className += ' open';
    }
  }

  var childMatch = function(type, regexp){
    var types = type.querySelectorAll("ul li");
    for (var j = 0; j < types.length; j ++) {
      var t = types[j];
      if(regexp.exec(t.getAttribute('data-name'))){ return true; }
    }
    return false;
  };

  Navigator = function(sidebar, searchInput, list){
    this.list = list;
    var self = this;

    function clearMoveTimeout() {
      clearTimeout(self.moveTimeout);
      self.moveTimeout = null;
    }

    function startMoveTimeout(upwards){
      /*if(self.moveTimeout) {
        clearMoveTimeout();
      }

      var go = function() {
        if (!self.moveTimeout) return;
        self.move(upwards);
        self.moveTimout = setTimeout(go, 600);
      };
      self.moveTimeout = setTimeout(go, 800);*/
    }

    var move = this.move = function(upwards){
      if(!this.current){
        this.highlightFirst();
        return true;
      }
      var next = upwards ? this.current.previousElementSibling : this.current.nextElementSibling;
      if(next && next.classList) {
        this.highlight(next);
        next.scrollIntoViewIfNeeded();
        return true;
      }
      return false;
    };

    this.moveRight = function(){
    };
    this.moveLeft = function(){
    };

    this.highlight = function(elem) {
      if(!elem){
        return;
      }
      if(this.current){
        this.current.classList.remove("current");
      }

      this.current = elem;
      this.current.classList.add("current");
    };

    this.highlightFirst = function(){
      this.highlight(this.list.querySelector('li:first-child'));
    };

    function handleKeyUp(event) {
      switch(event.key) {
        case "ArrowUp":
        case "ArrowDown":
        case "i":
        case "j":
        case "k":
        case "l":
        case "c":
        case "h":
        case "t":
        case "n":
        event.stopPropagation();
        clearMoveTimeout();
      }
    }

    function handleKeyDown(event) {
      switch(event.key) {
        case "Enter":
          event.stopPropagation();
          self.current.click();
          break;
        case "Escape":
          event.stopPropagation();
          CrystalDoc.toggleResultsList(false);
          sessionStorage.setItem(repositoryName + '::search-input:value', "");
          break;
        case "i":
        case "c":
          if(!event.ctrlKey) {
            break;
          }
        case "ArrowUp":
          event.stopPropagation();
          self.move(true);
          startMoveTimeout(true);
          break;
        case "j":
        case "h":
          if(!event.ctrlKey) {
            break;
          }
        case "ArrowDown":
          event.stopPropagation();
          self.move(false);
          startMoveTimeout(false);
          break;
        case "k":
        case "t":
          if(!event.ctrlKey) {
            break;
          }
        case "ArrowLeft":
          event.stopPropagation();
          self.moveLeft();
          break;
        case "l":
        case "n":
          if(!event.ctrlKey) {
            break;
          }
        case "ArrowRight":
          event.stopPropagation();
          self.moveRight();
          break;
      }
    }

    function handleInputKeyUp(event) {
      switch(event.key) {
        case "ArrowUp":
        case "ArrowDown":
        clearMoveTimeout();
      }
    }

    function handleInputKeyDown(event) {
      switch(event.key) {
        case "Enter":
          event.stopPropagation();
          self.current.click();
          break;
        case "Escape":
          event.stopPropagation();
          event.preventDefault();
          // remove focus from search input
          sidebar.focus();
          break;
        case "ArrowUp":
          event.stopPropagation();
          event.preventDefault();
          self.move(true);
          startMoveTimeout(true);
          break;

        case "ArrowDown":
          event.stopPropagation();
          event.preventDefault();
          self.move(false);
          startMoveTimeout(false);
          break;
      }
    }

    sidebar.tabIndex = 100; // set tabIndex to enable keylistener
    sidebar.addEventListener('keyup', function(event) {
      handleKeyUp(event);
    });
    sidebar.addEventListener('keydown', function(event) {
      handleKeyDown(event);
    });
    searchInput.addEventListener('keydown', function(event) {
      handleInputKeyDown(event);
    });
    searchInput.addEventListener('keyup', function(event) {
      handleInputKeyUp(event);
    });
    this.move();
  };
  var navigator = new Navigator(document.querySelector('.sidebar'), searchInput, document.querySelector(".search-results"));

  CrystalDoc.loadIndex();
  var searchTimeout;
  var lastSearchText = false;
  var performSearch = function() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(function() {
      var text = searchInput.value;

      if(text == "") {
        CrystalDoc.toggleResultsList(false);
      }else if(text != lastSearchText){
        CrystalDoc.search(text);
        navigator.highlightFirst();
        searchInput.focus();
      }
      lastSearchText = text;
      sessionStorage.setItem(repositoryName + '::search-input:value', text);
    }, 200);
  };

  if (searchInput.value.length > 0) {
    document.addEventListener('CrystalDoc:loaded', performSearch);
  }else {
    var searchText = sessionStorage.getItem(repositoryName + '::search-input:value');
    if(searchText){
      searchInput.value = searchText;
      document.addEventListener('CrystalDoc:loaded', performSearch);
    }
  }
  searchInput.focus();
  searchInput.addEventListener('keyup', performSearch);
  searchInput.addEventListener('input', performSearch);

  function handleShortkeys(event) {
    switch(event.key) {
      case "?":
        // TODO: Show help
        break;

      case "s":
      case "/":
        event.stopPropagation();
        searchInput.focus();
        break;
    }
  }

  document.addEventListener('keyup', handleShortkeys);

  typesList.onscroll = function() {
    var y = typesList.scrollTop;
    sessionStorage.setItem(repositoryName + '::types-list:scrollTop', y);
  };

  var initialY = parseInt(sessionStorage.getItem(repositoryName + '::types-list:scrollTop') + "", 10);
  if(initialY > 0) {
    typesList.scrollTop = initialY;
  }

  var scrollToEntryFromLocationHash = function() {
    var hash = window.location.hash;
    if (hash) {
      var targetAnchor = unescape(hash.substr(1));
      var targetEl = document.querySelectorAll('.entry-detail[id="' + targetAnchor + '"]');

      if (targetEl && targetEl.length > 0) {
        targetEl[0].offsetParent.scrollTop = targetEl[0].offsetTop;
      }
    }
  };
  window.addEventListener("hashchange", scrollToEntryFromLocationHash, false);
  scrollToEntryFromLocationHash();
});
