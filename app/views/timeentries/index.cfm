<cfoutput>
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
                    &mdash; <a href="#encodeForHtmlAttribute(runTask.cardUrl())#" target="_blank" rel="noopener">###runTask.workItemId#</a>
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
                            <option value="#projectCodes.id#" <cfif IsObject(defaultProjectCode) AND defaultProjectCode.id EQ projectCodes.id>selected</cfif>>#projectCodes.code# &ndash; #encodeForHtml(projectCodes.description)#</option>
                        </cfloop>
                    </select>
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

<!--- ===== Dashboard summary ===== --->
<div class="dashboard-stats">
    <div class="stat-card">
        <div class="stat-label">Today</div>
        <div class="stat-value">#formatMinutes(dashboardTodayMinutes)#</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">This week</div>
        <div class="stat-value">#formatMinutes(dashboardWeekMinutes)#</div>
    </div>
</div>

<div class="chart-card">
    <h3>Hours this week</h3>
    <cfif dashboardWeekMinutes GT 0>
        <canvas id="weekDailyChart" height="80"></canvas>
    <cfelse>
        <p class="text-muted">No time logged yet this week.</p>
    </cfif>
</div>

<div class="dashboard-charts">
    <div class="chart-card">
        <h3>By code (this week)</h3>
        <cfif ArrayLen(dashboardWeekByCode)>
            <canvas id="weekByCodeChart"></canvas>
        <cfelse>
            <p class="text-muted">No time logged yet this week.</p>
        </cfif>
    </div>
    <div class="chart-card">
        <h3>By code (all time)</h3>
        <cfif ArrayLen(dashboardAllTimeByCode)>
            <canvas id="allTimeByCodeChart"></canvas>
        <cfelse>
            <p class="text-muted">No history yet.</p>
        </cfif>
    </div>
</div>

<!--- ===== Recent entries ===== --->
<h2>Recent entries <small style="font-weight:normal;color:##6b7280;">#dateFormat(fromStr, "mmm d")# &ndash; #dateFormat(toStr, "mmm d")#</small></h2>
<form method="get" action="#urlFor(route='timer')#" style="display:flex;gap:.75rem;align-items:flex-end;flex-wrap:wrap;margin-bottom:1rem;">
    <div>
        <label for="from" style="display:block;font-size:.85em;">From</label>
        <input type="date" name="from" id="from" value="#encodeForHtmlAttribute(fromStr)#">
    </div>
    <div>
        <label for="to" style="display:block;font-size:.85em;">To</label>
        <input type="date" name="to" id="to" value="#encodeForHtmlAttribute(toStr)#">
    </div>
    <button type="submit">Apply</button>
</form>
<cfif recentEntries.recordCount>
    <div style="grid-column:1 / -1;overflow-x:auto;padding:0 2rem;box-sizing:border-box;">
    <table class="table table-bordered align-middle entries-table" style="width:100%;">
        <thead>
            <tr><th>Date</th><th>Time</th><th>Duration</th><th>Code</th><th>Task</th><th>Notes</th><th></th></tr>
        </thead>
        <tbody>
            <cfloop query="recentEntries">
                <cfset rowCode = model("ProjectCode").findByKey(recentEntries.projectCode_id)>
                <cfset rowTask = Len(recentEntries.task_id ?: "") ? model("Task").findByKey(recentEntries.task_id) : false>
                <cfset startVal = dateFormat(recentEntries.startedAt, "yyyy-mm-dd") & "T" & timeFormat(recentEntries.startedAt, "HH:mm")>
                <cfset endVal = Len(recentEntries.endedAt ?: "") ? dateFormat(recentEntries.endedAt, "yyyy-mm-dd") & "T" & timeFormat(recentEntries.endedAt, "HH:mm") : ""> 
                <cfset taskUrl = IsObject(rowTask) ? (rowTask.url ?: "") : "">
                <cfset taskTitle = IsObject(rowTask) ? (rowTask.title ?: "") : "">
                <tr>
                    <td>#dateFormat(recentEntries.startedAt, "ddd mmm d")#</td>
                    <td>#timeFormat(recentEntries.startedAt, "h:mm tt")# &ndash; #timeFormat(recentEntries.endedAt, "h:mm tt")#</td>
                    <td>#formatMinutes(DateDiff("n", recentEntries.startedAt, recentEntries.endedAt))#</td>
                    <td>
                        <cfif IsObject(rowCode)>
                            <div style="max-width:12rem;overflow-wrap:anywhere;">
                                <span style="display:inline-block;width:.8rem;height:.8rem;border-radius:2px;vertical-align:middle;background:#rowCode.color#;"></span>
                                #rowCode.code# &ndash; #encodeForHtml(rowCode.description)#
                            </div>
                        </cfif>
                    </td>
                    <td>
                        <cfif IsObject(rowTask)>
                            <cfif Len(rowTask.title ?: "")>
                                <div style="max-width:14rem;overflow-wrap:anywhere;">#encodeForHtml(rowTask.title)#</div>
                                <hr style="margin:.4rem 0;">
                            </cfif>
                            <cfif Len(rowTask.workItemId ?: "") AND Len(rowTask.url ?: "")>
                                <a href="#encodeForHtmlAttribute(rowTask.cardUrl())#" target="_blank" rel="noopener">Task ###rowTask.workItemId#</a>
                            <cfelseif Len(rowTask.url ?: "")>
                                <a href="#encodeForHtmlAttribute(rowTask.cardUrl())#" target="_blank" rel="noopener">Card &##8599;</a>
                            </cfif>
                        <cfelse>
                            <em>ad-hoc</em>
                        </cfif>
                    </td>
                    <td><div style="max-width:16rem;overflow-wrap:anywhere;white-space:normal;">#encodeForHtml(recentEntries.notes ?: "")#</div></td>
                    <td style="white-space:nowrap;">
                        <span style="display:inline-block;margin-right:4px;vertical-align:middle;">#startFormTag(route="resumeEntry", key=recentEntries.id, method="post")##submitTag(value="▶ Resume")##endFormTag()#</span>
                        <button type="button" class="edit-entry-toggle" data-entry-id="#recentEntries.id#" style="margin-right:4px;">Edit</button>
                        <span style="display:inline-block;vertical-align:middle;">#startFormTag(route="deleteTimeEntry", key=recentEntries.id, method="post", id="delete-form-#recentEntries.id#")##submitTag(value="Delete", onclick="return confirm('Delete this entry? This cannot be undone.');", style="background:##dc3545;color:white;border:none;padding:4px 8px;border-radius:3px;cursor:pointer;font-size:12px;")##endFormTag()#</span>
                    </td>
                </tr>
                <tr class="edit-entry-row" id="edit-row-#recentEntries.id#" style="display:none;">
                    <td colspan="7" style="padding:0;">
                        #startFormTag(route="updateTimeEntry", key=recentEntries.id, method="post")#
                            <div class="inline-edit-row" style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;padding:1rem;background:##f9fafb;border-top:1px solid ##ddd;">
                                <div>
                                    <label for="projectCode_id_#recentEntries.id#">Project code</label>
                                    <select name="projectCode_id" id="projectCode_id_#recentEntries.id#">
                                        <option value="">-- select --</option>
                                        <cfloop query="projectCodes">
                                            <option value="#projectCodes.id#" <cfif IsObject(rowCode) AND rowCode.id EQ projectCodes.id>selected</cfif>>#projectCodes.code# &ndash; #encodeForHtml(projectCodes.description)#</option>
                                        </cfloop>
                                    </select>
                                </div>
                                <div>
                                    <label for="url_#recentEntries.id#">Task card URL</label>
                                    <input type="url" name="url" id="url_#recentEntries.id#" value="#encodeForHtmlAttribute(taskUrl)#" placeholder="https://dev.azure.com/&hellip;/_workitems/edit/12345" style="width:100%;">
                                </div>
                                <div>
                                    <label for="startedAt_#recentEntries.id#">Start</label>
                                    <input type="datetime-local" name="startedAt" id="startedAt_#recentEntries.id#" step="60" value="#startVal#" style="width:100%;">
                                </div>
                                <div>
                                    <label for="title_#recentEntries.id#">Title <small>(for a new card)</small></label>
                                    <input type="text" name="title" id="title_#recentEntries.id#" value="#encodeForHtmlAttribute(taskTitle)#" style="width:100%;">
                                </div>
                                <div>
                                    <label for="endedAt_#recentEntries.id#">End</label>
                                    <input type="datetime-local" name="endedAt" id="endedAt_#recentEntries.id#" step="60" value="#endVal#" style="width:100%;">
                                </div>
                                <div>
                                    <label for="notes_#recentEntries.id#">Notes</label>
                                    <input type="text" name="notes" id="notes_#recentEntries.id#" value="#encodeForHtmlAttribute(recentEntries.notes ?: '')#" style="width:100%;">
                                </div>
                                <div style="grid-column:1 / -1;display:flex;gap:.5rem;justify-content:space-between;">
                                    <button type="submit" form="delete-form-#recentEntries.id#" onclick="return confirm('Delete this entry? This cannot be undone.');" style="background:##dc3545;color:white;border:none;padding:6px 12px;border-radius:4px;cursor:pointer;">Delete</button>
                                    <div style="display:flex;gap:.5rem;">
                                        #submitTag(value="Save")#
                                        <button type="button" class="edit-entry-cancel" data-entry-id="#recentEntries.id#">Cancel</button>
                                    </div>
                                </div>
                            </div>
                        #endFormTag()#
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
    </div>
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
<script>
(function () {
    var toggleButtons = document.querySelectorAll('.edit-entry-toggle');
    var cancelButtons = document.querySelectorAll('.edit-entry-cancel');

    function hideRow(id) {
        var row = document.getElementById('edit-row-' + id);
        if (row) {
            row.style.display = 'none';
        }
    }

    function showRow(id) {
        var row = document.getElementById('edit-row-' + id);
        if (row) {
            row.style.display = 'table-row';
        }
    }

    toggleButtons.forEach(function (button) {
        button.addEventListener('click', function () {
            var id = button.getAttribute('data-entry-id');
            var row = document.getElementById('edit-row-' + id);
            if (!row) {
                return;
            }
            row.style.display = row.style.display === 'table-row' ? 'none' : 'table-row';
        });
    });

    cancelButtons.forEach(function (button) {
        button.addEventListener('click', function () {
            hideRow(button.getAttribute('data-entry-id'));
        });
    });
})();
</script>
<script src="/vendor/chartjs/chart.umd.min.js"></script>
<script>
(function () {
    var weekDaily = #ToString(SerializeJSON(dashboardWeekDaily))#;
    var weekByCode = #ToString(SerializeJSON(dashboardWeekByCode))#;
    var allTimeByCode = #ToString(SerializeJSON(dashboardAllTimeByCode))#;

    function hours(mins) { return Math.round((mins / 60) * 10) / 10; }

    // Lucee's SerializeJSON() always uppercases struct keys, regardless of how
    // they were declared in CFML -- read LABEL/MINUTES/COLOR, not label/minutes/color.
    var dailyEl = document.getElementById('weekDailyChart');
    if (dailyEl && weekDaily.length) {
        new Chart(dailyEl, {
            type: 'bar',
            data: {
                labels: weekDaily.map(function (d) { return d.LABEL; }),
                datasets: [{ label: 'Hours', data: weekDaily.map(function (d) { return hours(d.MINUTES); }), backgroundColor: '##4f46e5' }]
            },
            options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
        });
    }

    var weekByCodeEl = document.getElementById('weekByCodeChart');
    if (weekByCodeEl && weekByCode.length) {
        new Chart(weekByCodeEl, {
            type: 'bar',
            data: {
                labels: weekByCode.map(function (c) { return c.LABEL; }),
                datasets: [{ label: 'Hours', data: weekByCode.map(function (c) { return hours(c.MINUTES); }), backgroundColor: weekByCode.map(function (c) { return c.COLOR; }) }]
            },
            options: { indexAxis: 'y', plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true } } }
        });
    }

    var allTimeEl = document.getElementById('allTimeByCodeChart');
    if (allTimeEl && allTimeByCode.length) {
        new Chart(allTimeEl, {
            type: 'bar',
            data: {
                labels: allTimeByCode.map(function (c) { return c.LABEL; }),
                datasets: [{ label: 'Hours', data: allTimeByCode.map(function (c) { return hours(c.MINUTES); }), backgroundColor: allTimeByCode.map(function (c) { return c.COLOR; }) }]
            },
            options: { indexAxis: 'y', plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true } } }
        });
    }
})();
</script>
</cfoutput>
