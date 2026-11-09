// Verso binds initial-page tokens at load time. Declaration previews arrive later.
// Delegate only within declarations that opted into registered source, reusing
// the normal page/cache hover IDs and the same Tippy and Markdown dependencies.
(function () {
function renderDocstrings(root, selector) {
  if (typeof marked === "undefined") return;
  for (const doc of root.querySelectorAll(selector)) {
    const visible = doc.cloneNode(true);
    visible.querySelectorAll("[hidden]").forEach(node => node.remove());
    const prose = document.createElement("div");
    prose.className = "docstring";
    prose.innerHTML = marked.parse(visible.textContent || "");
    doc.replaceWith(prose);
  }
}
async function start() {
  if (window.bpNumberedIdentities && window.fuzzysort) {
    blueprintInstallNumberSearch(window.bpNumberedIdentities, window.fuzzysort, window.searchIndex);
  }
  if (typeof tippy === "undefined" || typeof tippy.delegate !== "function") return;
  const response = await fetch("-verso-docs.json");
  if (!response.ok) return;
  const docs = await response.json();
  const docSelector = ".declaration:has(.bp_external_decl_source_code) " +
    ":is(pre, code).docstring";
  renderDocstrings(document, docSelector);
  new MutationObserver(records => {
    for (const record of records) for (const node of record.addedNodes) {
      if (node.nodeType === 1) renderDocstrings(node, docSelector);
    }
  }).observe(document.body, { childList: true, subtree: true });
  tippy.delegate(document.body, {
    target: ".declaration:has(.bp_external_decl_source_code) [data-verso-hover]",
    theme: "lean",
    interactive: true,
    delay: [100, 0],
    maxWidth: "none",
    appendTo: () => document.body,
    content(reference) {
      const content = document.createElement("span");
      content.className = "hl lean";
      content.style.display = "block";
      content.style.maxHeight = "300px";
      content.style.overflowY = "auto";
      content.innerHTML = docs[reference.dataset.versoHover] || "";
      renderDocstrings(content, "pre.docstring, code.docstring");
      return content;
    }
  });
}
if (document.readyState === "complete") void start();
else window.addEventListener("load", start);
})();

// Optional numbered-identity domains use exact token matching. Verso's default
// fuzzy matcher otherwise treats 4.20 as a result for 4.2. Keep its own UI,
// keyboard navigation, domain rendering and destination resolution.
function blueprintNumberQuery(query) {
  return /^(?:(?:theorem|lemma|proposition|claim|corollary|definition|remark|question|algorithm)\s+)?\d+\.\d+$/i
    .test(query.trim());
}
function blueprintInstallNumberSearch(identities, fuzzy, textIndex) {
  if (fuzzy.blueprintNumberSearch) return;
  fuzzy.blueprintNumberSearch = true;
  const known = new Set(identities.map(s => s.toLowerCase()));
  const go = fuzzy.go.bind(fuzzy);
  fuzzy.go = (query, targets, options) => {
    if (blueprintNumberQuery(query) && known.has(query.trim().toLowerCase())) {
      targets = targets.filter(t => known.has(t.target.toLowerCase()) &&
        t.target.toLowerCase() === query.trim().toLowerCase());
    }
    return go(query, targets, options);
  };
  if (textIndex) {
    const search = textIndex.search.bind(textIndex);
    textIndex.search = (query, options) =>
      blueprintNumberQuery(query) && known.has(query.trim().toLowerCase()) ? [] :
        search(query, options);
  }
}
if (typeof document !== 'undefined' && typeof document.addEventListener === 'function') {
  document.addEventListener('DOMContentLoaded', () => {
    if (window.bpNumberedIdentities && window.fuzzysort) {
      blueprintInstallNumberSearch(window.bpNumberedIdentities, window.fuzzysort, window.searchIndex);
    }
  });
}
