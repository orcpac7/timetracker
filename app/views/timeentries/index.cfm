<cfoutput>
<p style="float:right;">#linkTo(text="Project codes", controller="projectCodes", action="index")#</p>
<h1>Time Tracker</h1>

<cfif IsObject(running)>
    <!--- ===== A timer is running ===== --->
    <cfset runCode = model("ProjectCode").findByKey(running.projectCode_id)>
    <cfset runTask = Len(running.task_id ?: "") ? model("Task").findByKey(running.task_id) : false>
    <cfset elapsedSeconds = DateDiff("s", running.startedAt, now())>

    <div style="border:2px solid ##16a34a;border-radius:8px;padding:1rem;margin-bottom:1.5rem;">
        <h2 style="margin-top:0;">▶ Running &mdash; <span id="elapsed" data-seconds="#elapsedSeconds#">#formatMinutes(DateDiff("n", running.startedAt, now()))#</span></h2>
        <p>
            <cfif IsObject(runCode)>
                <span style="display:inline-block;width:.8rem;height:.8rem;border-radius:2px;vertical-align:middle;background:#runCode.color#;"></span>
                <strong>#runCode.code#</strong> #runCode.description#
            </cfif>
        </p>
        <cfif IsObject(runTask)>
            <p>
                #encodeForHtml(runTask.title)#
                <cfif Len(runTask.workItemId ?: "") AND Len(runTask.url ?: "")>
                    &mdash; <a href="#encodeForHtmlAttribute(runTask.url)#" target="_blank" rel="noopener">###runTask.workItemId#</a>
                </cfif>
            </p>
        <cfelse>
            <p><em>Ad-hoc (no card)</em></p>
        </cfif>
        <cfif Len(running.notes ?: "")><p>#encodeForHtml(running.notes)#</p></cfif>
        <p><small>Started #timeFormat(running.startedAt, "h:mm tt")# (#dateFormat(running.startedAt, "ddd mmm d")#)</small></p>

        #startFormTag(controller="timeEntries", action="stop", method="post")#
            #submitTag(value="⏹ Stop")#
        #endFormTag()#
    </div>

<cfelse>
    <!--- ===== No timer running: show the start form ===== --->
    <div style="border:1px solid ##ccc;border-radius:8px;padding:1rem;margin-bottom:1.5rem;">
        <h2 style="margin-top:0;">Start working</h2>
        <cfif projectCodes.recordCount EQ 0>
            <p>You need at least one project code first. #linkTo(text="Add a project code", controller="projectCodes", action="new")#.</p>
        <cfelse>
            #startFormTag(controller="timeEntries", action="start", method="post")#
                <div class="field">
                    <label for="projectCode_id">Project code</label>
                    <select name="projectCode_id" id="projectCode_id">
                        <option value="">-- select --</option>
                        <cfloop query="projectCodes">
                            <option value="#projectCodes.id#">#projectCodes.code# &ndash; #encodeForHtml(projectCodes.description)#</option>
                        </cfloop>
                    </select>
                    <small>Used when creating a new card, or for ad-hoc work.</small>
                </div>
                <div class="field">
                    <label for="url">Task card URL <small>(optional)</small></label>
                    <input type="url" name="url" id="url" placeholder="https://dev.azure.com/&hellip;/_workitems/edit/12345" style="width:100%;">
                </div>
                <div class="field">
                    <label for="title">Title <small>(for a new card)</small></label>
                    <input type="text" name="title" id="title" style="width:100%;">
                </div>
                <div class="field">
                    <label for="notes">Notes <small>(optional)</small></label>
                    <input type="text" name="notes" id="notes" style="width:100%;">
                </div>
                #submitTag(value="▶ Start")#
            #endFormTag()#
        </cfif>
    </div>
</cfif>

<!--- ===== Recent entries ===== --->
<h2>Recent entries</h2>
<cfif recentEntries.recordCount>
    <table>
        <thead>
            <tr><th>Date</th><th>Time</th><th>Duration</th><th>Code</th><th>Task</th><th>Notes</th></tr>
        </thead>
        <tbody>
            <cfloop query="recentEntries">
                <cfset rowCode = model("ProjectCode").findByKey(recentEntries.projectCode_id)>
                <cfset rowTask = Len(recentEntries.task_id ?: "") ? model("Task").findByKey(recentEntries.task_id) : false>
                <tr>
                    <td>#dateFormat(recentEntries.startedAt, "ddd mmm d")#</td>
                    <td>#timeFormat(recentEntries.startedAt, "h:mm tt")# &ndash; #timeFormat(recentEntries.endedAt, "h:mm tt")#</td>
                    <td>#formatMinutes(DateDiff("n", recentEntries.startedAt, recentEntries.endedAt))#</td>
                    <td>
                        <cfif IsObject(rowCode)>
                            <span style="display:inline-block;width:.8rem;height:.8rem;border-radius:2px;vertical-align:middle;background:#rowCode.color#;"></span>
                            #rowCode.code#
                        </cfif>
                    </td>
                    <td>
                        <cfif IsObject(rowTask)>
                            #encodeForHtml(rowTask.title)#
                            <cfif Len(rowTask.workItemId ?: "") AND Len(rowTask.url ?: "")>
                                <a href="#encodeForHtmlAttribute(rowTask.url)#" target="_blank" rel="noopener">###rowTask.workItemId#</a>
                            </cfif>
                        <cfelse>
                            <em>ad-hoc</em>
                        </cfif>
                    </td>
                    <td>#encodeForHtml(recentEntries.notes ?: "")#</td>
                </tr>
            </cfloop>
        </tbody>
    </table>
<cfelse>
    <p>No entries yet. Start your first timer above.</p>
</cfif>

<cfif IsObject(running)>
<script>
(function () {
    var el = document.getElementById('elapsed');
    if (!el) return;
    var secs = parseInt(el.getAttribute('data-seconds'), 10) || 0;
    function fmt(s) {
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), ss = s % 60;
        return (h > 0 ? h + 'h ' : '') + m + 'm ' + (ss < 10 ? '0' : '') + ss + 's';
    }
    function tick() { el.textContent = fmt(secs); secs++; }
    tick();
    setInterval(tick, 1000);
})();
</script>
</cfif>
</cfoutput>
