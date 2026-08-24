<!--- Copy button shared by the email renders of the daily report. Both views wrap
      their copyable region in an element with id="emailReport". --->
<p>
    <button type="button" id="copyBtn" onclick="copyEmailReport()">Copy for email</button>
    <span id="copyStatus" style="margin-left:.75rem;color:#16a34a;"></span>
</p>

<script>
// Copy the email-safe region to the clipboard as rich HTML (so Outlook keeps
// the table layout and spacing), with a plain-text fallback for older browsers.
function copyEmailReport() {
    var el = document.getElementById("emailReport");
    var status = document.getElementById("copyStatus");
    var html = el.innerHTML;
    var text = el.innerText;

    function done() {
        status.style.color = "#16a34a";
        status.textContent = "Copied — paste into your email.";
        setTimeout(function () { status.textContent = ""; }, 4000);
    }
    function fail() {
        status.style.color = "#b91c1c";
        status.textContent = "Copy failed — select the report and press Ctrl+C.";
    }

    if (navigator.clipboard && window.ClipboardItem) {
        var item = new ClipboardItem({
            "text/html": new Blob([html], { type: "text/html" }),
            "text/plain": new Blob([text], { type: "text/plain" })
        });
        navigator.clipboard.write([item]).then(done).catch(fallbackCopy);
    } else {
        fallbackCopy();
    }

    // Fallback: select the region and use execCommand so the rich HTML is copied.
    function fallbackCopy() {
        try {
            var range = document.createRange();
            range.selectNodeContents(el);
            var sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(range);
            var ok = document.execCommand("copy");
            sel.removeAllRanges();
            ok ? done() : fail();
        } catch (e) {
            fail();
        }
    }
}
</script>
