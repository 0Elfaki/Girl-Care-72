/* Fills the page from the content the team edits in the dashboard (Website & app).
   If the server cannot be reached, the text already in the page stays. */
(function () {
  "use strict";
  var API = (window.GC_API_BASE || "").replace(/\/$/, "");
  var DEFAULT_EXIT = "https://www.google.com/search?q=weather+arua";
  var exitUrl = DEFAULT_EXIT;

  function el(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function kb(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB" : Math.round(b / 1024) + " KB"; }

  // Quick exit: replace this page in history so the back button cannot return to it.
  function quickExit() { try { document.body.innerHTML = ""; } catch (e) {} window.location.replace(exitUrl); }
  document.getElementById("quickexit").addEventListener("click", quickExit);
  document.addEventListener("keydown", function (e) { if (e.key === "Escape") quickExit(); });

  function render(s) {
    if (s.published === false) {
      document.getElementById("main").innerHTML = "";
      var box = el("div", "offline"); box.appendChild(el("h1", null, "Coming soon")); box.appendChild(el("p", "lead", "For help now, flash or call " + (s.free_number || "the free number") + "."));
      document.getElementById("main").appendChild(box);
      return;
    }
    if (s.quick_exit_url && /^https:\/\//.test(s.quick_exit_url)) exitUrl = s.quick_exit_url;
    document.querySelectorAll("[data-c]").forEach(function (node) {
      var k = node.getAttribute("data-c");
      if (k === "brand") return; // keeps the two-colour wordmark
      if (typeof s[k] === "string" && s[k]) node.textContent = s[k];
    });
    if (s.brand) document.title = s.brand;

    var ways = document.getElementById("ways-list"); ways.innerHTML = "";
    (s.ways || []).forEach(function (w) { var li = el("li"); li.appendChild(el("h3", null, w.title)); li.appendChild(el("p", "muted", w.text)); ways.appendChild(li); });

    var feats = document.getElementById("features-list"); feats.innerHTML = "";
    (s.features || []).forEach(function (f) { var a = el("article"); a.appendChild(el("h3", null, f.title)); a.appendChild(el("p", "muted", f.text)); feats.appendChild(a); });

    var steps = document.getElementById("dl-steps"); steps.innerHTML = "";
    (s.download_steps || []).forEach(function (t) { steps.appendChild(el("li", null, t)); });

    var pl = document.getElementById("partners-list"); pl.innerHTML = "";
    (s.partners || []).forEach(function (p) { pl.appendChild(el("li", null, p)); });

    var faq = document.getElementById("faq-list"); faq.innerHTML = "";
    (s.faq || []).forEach(function (f) { var d = el("details"); d.appendChild(el("summary", null, f.q)); d.appendChild(el("p", null, f.a)); faq.appendChild(d); });

    var card = document.getElementById("dl-card"); card.innerHTML = "";
    // The server's release wins; otherwise the APK uploaded with this site (assets/data/release.json).
    var r = s.release || localRelease;
    var base = s.release ? API : "";
    if (r) {
      card.appendChild(el("p", "eyebrow", "Android app"));
      card.appendChild(el("h3", null, "GirlCare72 " + r.version));
      var a = el("a", "btn primary", "Download (" + kb(r.size) + ")");
      a.href = base + r.url; a.setAttribute("download", "GirlCare72-" + r.version + ".apk"); a.rel = "nofollow";
      card.appendChild(a);
      if (r.qr) {
        var qr = el("figure", "dl-qr");
        var img = el("img"); img.src = r.qr; img.alt = "QR code to download GirlCare72"; img.width = 180; img.height = 180;
        qr.appendChild(img);
        qr.appendChild(el("figcaption", "muted", "On a computer or another phone? Scan this to download."));
        card.appendChild(qr);
      }
      var web = el("p", "muted", "No Android phone? ");
      var wl = el("a", null, "Open GirlCare72 in your browser"); wl.href = "app/"; web.appendChild(wl);
      card.appendChild(web);
      var dl = el("dl", "dl-meta");
      [["Version", r.version], ["Size", kb(r.size)], ["Updated", r.updated], ["What's new", r.notes || "–"]].forEach(function (row) { dl.appendChild(el("dt", null, row[0])); dl.appendChild(el("dd", null, row[1])); });
      var dt = el("dt", null, "SHA-256"); var dd = el("dd", "hash", r.sha256); dl.appendChild(dt); dl.appendChild(dd);
      card.appendChild(dl);
      card.appendChild(el("p", "muted", "No smartphone? Flash " + (s.free_number || "the free number") + " or text LEARN for lessons by SMS."));
    } else {
      card.appendChild(el("h3", null, "The app is coming soon"));
      var b = el("a", "btn primary", "Download"); b.setAttribute("aria-disabled", "true"); card.appendChild(b);
      card.appendChild(el("p", "muted", "Until then, flash " + (s.free_number || "the free number") + " or text HELP for a call back."));
    }
  }

  var localRelease = null;

  function load() {
    fetch("assets/data/release.json", { cache: "no-cache" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; })
      .then(function (rel) { localRelease = rel; loadSite(); });
  }

  function loadSite() {
    fetch(API + "/api/public/site", { credentials: "omit" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(render)
      .catch(function () {
        fetch("assets/data/content.default.json").then(function (r) { return r.json(); }).then(function (s) { s.release = null; render(s); }).catch(function () {});
      });
  }
  load();
})();
