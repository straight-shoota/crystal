window.CrystalDoc = window.CrystalDoc || {};
CrystalDoc.searchIndex = false;
CrystalDoc.MAX_RESULTS_DISPLAY = 140;

CrystalDoc.run_query = function(query) {
  function search_type(type, query, results) {
    var name = type.full_name;
    var i = name.lastIndexOf("::");
    if (i > 0) {
      name = name.substring(i + 2);
    }
    var matches = query.matches(name);
    if (matches) {
      results.push({
        id: type.id,
        result_type: "type",
        kind: type.kind,
        name: type.full_name,
        href: type.path,
        summary: type.summary,
        matched_fields: ["name"],
        matched_terms: matches
      });
    }

    search_methods(
      type.instance_methods,
      type,
      "instance_method",
      query,
      results
    );
    search_methods(type.class_methods, type, "class_method", query, results);
    search_methods(type.macros, type, "macro", query, results);
    type.constants.forEach(function(constant){
      search_constant(constant, type, query, results);
    });

    type.types.forEach(function(subtype){
      search_type(subtype, query, results);
    });
  }

   function search_methods(methods, type, kind, query, results) {
    methods.forEach(function (method) {
      search_method(method, type, kind, query, results);
    });
  }

  function search_method(method, type, kind, query, results) {
    var matches = [];
    var matched_fields = [];
    method.args.forEach(function(arg){
      var arg_matches = query.matches(arg.external_name);
      if (arg_matches) {
        matches = matches.concat(arg_matches);
        matched_fields.push("args");
      }
    });
    var arg_matches = matches.length > 0;
    var name_matches = query.matches_method(method.name, kind);
    if (name_matches) {
      matches = matches.concat(name_matches);
      matched_fields.push("name");
    }

    if (matches.length > 0) {
      var type_matches = query.matches(type.full_name);
      if (type_matches) {
        matched_fields.push("type");
        matches = matches.concat(type_matches);
      }
      results.push({
        id: method.id,
        type: type.full_name,
        result_type: kind,
        name: method.name,
        args_string: method.args_string,
        summary: method.summary,
        href: type.path + "#" + method.id,
        matched_fields: matched_fields,
        matched_terms: matches
      });
    }
  }

  function search_constant(constant, type, query, results) {
    var matches = query.matches(constant.name);
    if (matches) {
      var matched_fields = ["name"];
      var type_matches = query.matches(type.full_name);
      if (type_matches) {
        matched_fields.push("type");
        matches = matches.concat(type_matches);
      }
      results.push({
        id: constant.id,
        type: type.full_name,
        result_type: "constant",
        name: constant.name,
        value: constant.value,
        summary: constant.summary,
        href: type.path + "#" + constant.id,
        matched_fields: matched_fields,
        matched_terms: matches
      });
    }
  }

  var results = [];
  search_type(CrystalDoc.searchIndex.program, query, results);
  return results;
};

CrystalDoc.rank_results = function(results, query) {
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
    var matched_terms_diff = uniqueArray(b.matched_terms).length - uniqueArray(a.matched_terms).length;
    if (matched_terms_diff != 0) {
      return matched_terms_diff;
    }

    if (a.result_type == "type" && b.result_type != "type") {
      return -1;
    } else if (b.result_type == "type" && a.result_type != "type") {
      return 1;
    }
    if (a.matched_fields.includes("name")) {
      if (b.matched_fields.includes("name")) {
        var a_name = CrystalDoc.prefix_for_type(a.result_type) + a.name;
        var b_name = CrystalDoc.prefix_for_type(b.result_type) + b.name;
        query.terms.forEach(function(term){
          var a_orig_index = a_name.indexOf(term);
          var b_orig_index = b_name.indexOf(term);
          if (a_orig_index >= 0) {
            if (b_orig_index >= 0) {
              return a_orig_index - b_orig_index;
            } else {
              return -1;
            }
          } else if (b_orig_index >= 0) {
            return 1;
          }
        });
      } else {
        return -1;
      }
    } else if (
      !a.matched_fields.includes("name") &&
      b.matched_fields.includes("name")
    ) {
      return 1;
    }

    var matched_fields_diff = b.matched_fields.length - a.matched_fields.length;
    if (matched_fields_diff != 0) {
      return matched_fields_diff;
    }

    return a.name.localeCompare(b.name);
  });

  if (results.length > 1) {
    var best_matched_terms = uniqueArray(results[0].matched_terms).length;

    results = results.filter(function(result) {
      return uniqueArray(result.matched_terms).length + 1 >= best_matched_terms;
    });
  }
  return results;
};

CrystalDoc.prefix_for_type = function(type) {
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

CrystalDoc.display_search_results = function(results, query) {
  // limit results
  if (results.length > CrystalDoc.MAX_RESULTS_DISPLAY) {
    results = results.slice(0, CrystalDoc.MAX_RESULTS_DISPLAY);
  }

  var frag = document.createDocumentFragment();
  var results_elem = document.querySelector(".search-list");
  results_elem.innerHTML = "<!--" + JSON.stringify(query) + "-->";

  results.forEach(function(result, i) {
    var url = CrystalDoc.base_path + result.href;
    var type = false;

    elem = document.createElement("li");
    elem.className = "search-result search-result--" + result.result_type;
    elem.dataset.href = url;

    var title = query.highlight(result.name);

    var prefix = CrystalDoc.prefix_for_type(result.result_type);
    if (prefix) {
      title = "<b>" + prefix + "</b>" + title;
    }

    title = "<strong>" + title + "</strong>";

    if (result.args_string) {
      title +=
        "<span class=\"args\">" + query.highlight(result.args_string) + "</span>";
    }

    var title_elem = document.createElement("div");
    title_elem.setAttribute("class", "search-result__title");
    var title_link = document.createElement("a");
    title_link.setAttribute("href", url);

    title_link.innerHTML = title;
    title_elem.appendChild(title_link);
    elem.appendChild(title_elem);
    elem.addEventListener("click", function() {
      title_link.click();
    });

    if (result.result_type !== "type") {
      var type_elem = document.createElement("div");
      type_elem.setAttribute("class", "search-result__type");
      type_elem.innerHTML = query.highlight(result.type);
      elem.appendChild(type_elem);
    }

    var doc_elem = document.createElement("div");
    doc_elem.setAttribute("class", "search-result__doc");

    doc_elem.innerHTML =
      query.highlight(result.summary) + "<!--" + JSON.stringify(result) + "-->";

    elem.appendChild(doc_elem);
    frag.appendChild(elem);
  });

  results_elem.appendChild(frag);

  CrystalDoc.toggle_results_list(true);
};

CrystalDoc.toggle_results_list = function(visible) {
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

  var normalized = this.terms.map(CrystalDoc.Query.normalize_term);
  this.normalized = normalized;

  function run_matcher(field, matcher) {
    if (!field) {
      return false;
    }
    var normalized_value = CrystalDoc.Query.normalize_term(field);

    var matches = [];
    normalized.forEach(function(term) {
      if (matcher(normalized_value, term)) {
        matches.push(term);
      }
    });
    return matches.length > 0 ? matches : false;
  }

  this.matches = function(field) {
    return run_matcher(field, function(normalized, term) {
      if (term[0] == "#" || term[0] == ".") {
        return false;
      }
      return normalized.indexOf(term) >= 0;
    });
  };
  this.matches_method = function(name, kind) {
    return run_matcher(name, function(normalized, term) {
      switch (term[0]) {
        case "#":
          if (kind != "instance_method") {
            return false;
          }
          term = term.substring(1);
          break;

        case ".":
          if (kind != "class_method" && kind != "macro") {
            return false;
          }
          term = term.substring(1);
          break;
      }
      return normalized.indexOf(term) >= 0;
    });
  };

  this.highlight = function(string) {
    if (typeof string == "undefined") {
      return "";
    }
    function escapeRegExp(s) {
      return s.replace(/[.*+?\^${}()|\[\]\\]/g, "\\$&");
    }
    return string.replace(
      new RegExp("(" + this.normalized.map(escapeRegExp).join("|") + ")", "i"),
      "<mark>$1</mark>"
    );
  };
};
CrystalDoc.Query.normalize_term = function(term) {
  return term.toLowerCase();
};

CrystalDoc.search = function(string) {
  if(!CrystalDoc.searchIndex) {
    console.error("CrystalDoc search index not initialized.");
    return;
  }
  var query = new CrystalDoc.Query(string);
  var results = CrystalDoc.run_query(query);
  results = CrystalDoc.rank_results(results, query);
  CrystalDoc.display_search_results(results, query);
};

CrystalDoc.initialize_index = function(data) {
  CrystalDoc.searchIndex = data;

  document.dispatchEvent(new Event("CrystalDoc:loaded"));
};

CrystalDoc.load_index = function() {
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

  function parse_json(json) {
    CrystalDoc.initialize_index(JSON.parse(json));
  }

  for(var i = 0; i < document.scripts.length; i++){
    var script = document.scripts[i];
    if (script.src && script.src.indexOf("js/search.js") >= 0) {
      if (script.src.indexOf("file://") == 0) {
        json_path = script.src.replace("js/search.js", "index.jsonp");
        loadScript(json_path);
        return;
      } else {
        json_path = script.src.replace("js/search.js", "index.json");
        loadJSON(json_path, parse_json);
        return;
      }
    }
  }
  console.error("Could not find location of js/search.js");
};

// Callback for jsonp
function crystal_doc_search_index_callback(data) {
  CrystalDoc.initialize_index(data);
}
