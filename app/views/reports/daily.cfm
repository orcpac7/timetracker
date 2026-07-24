<cfoutput>
<p style="float:right;">#linkTo(text="Back to Time Tracker", controller="timeEntries", action="index")#</p>
<h1>Daily report</h1>

<!--- ===== Date navigation ===== --->
<cfset navSuffix = (includeExcluded ? "&includeExcluded=1" : "") & (showTimes ? "&showTimes=1" : "")>
<div style="display:flex;align-items:center;gap:1rem;flex-wrap:wrap;margin-bottom:1rem;">
    <a href="/report/daily?date=#prevDateStr##navSuffix#">&##9664; Prev</a>
    <strong style="font-size:1.1rem;">#dateFormat(reportDateStr, "dddd, mmm d, yyyy")#</strong>
    <a href="/report/daily?date=#nextDateStr##navSuffix#">Next &##9654;</a>
    <cfif reportDateStr NEQ todayStr>
        <a href="/report/daily?date=#todayStr##navSuffix#">Today</a>
    </cfif>
    <form method="get" action="/report/daily" style="margin:0;">
        <input type="date" name="date" value="#reportDateStr#">
        <cfif includeExcluded><input type="hidden" name="includeExcluded" value="1"></cfif>
        <cfif showTimes><input type="hidden" name="showTimes" value="1"></cfif>
        <button type="submit">Go</button>
    </form>
</div>

<!--- ===== Report toggles ===== --->
<form method="get" action="/report/daily" style="margin-bottom:1.5rem;display:flex;flex-direction:column;gap:.4rem;">
    <input type="hidden" name="date" value="#reportDateStr#">
    <cfif showTimes><input type="hidden" name="showTimes" value="1"></cfif>
    <label style="cursor:pointer;">
        <input type="checkbox" name="includeExcluded" value="1" <cfif includeExcluded>checked</cfif> onchange="this.form.submit()">
        Include personal / non-billable codes
    </label>
</form>
<form method="get" action="/report/daily" style="margin-bottom:1.5rem;">
    <input type="hidden" name="date" value="#reportDateStr#">
    <cfif includeExcluded><input type="hidden" name="includeExcluded" value="1"></cfif>
    <label style="cursor:pointer;">
        <input type="checkbox" name="showTimes" value="1" <cfif showTimes>checked</cfif> onchange="this.form.submit()">
        Show times
    </label>
</form>

<cfif ArrayLen(groups)>
    <cfloop array="#groups#" index="g">
        <div style="margin-bottom:1.75rem;">
            <!--- Group heading: the project code --->
            <h2 style="margin-bottom:.5rem;font-size:1.05rem;border-bottom:1px solid ##ddd;padding-bottom:.25rem;">
                <span style="display:inline-block;width:.8rem;height:.8rem;border-radius:2px;vertical-align:middle;background:#g.code.color#;"></span>
                #g.code.code# &ndash; #encodeForHtml(g.code.description)#
                <cfif g.excluded><small style="color:##6b7280;">(non-billable)</small></cfif>
                <cfif showTimes><span style="float:right;font-weight:normal;">Subtotal: <strong>#formatMinutes(g.totalMinutes)#</strong></span></cfif>
            </h2>

            <!--- One line per task (same-task sessions summed); notes below --->
            <cfloop array="#g.lines#" index="e">
                <div style="padding:.4rem 0;border-bottom:1px solid ##f0f0f0;">
                    <div style="display:flex;gap:1rem;align-items:baseline;flex-wrap:wrap;">
                        <span style="flex:1;min-width:12rem;font-weight:600;">
                            <cfif IsObject(e.task) AND Len(e.task.title ?: "")>
                                #encodeForHtml(e.task.title)#
                            <cfelse>
                                <span style="color:##6b7280;font-weight:normal;">Ad-hoc</span>
                            </cfif>
                        </span>
                        <cfif showTimes>
                            <span style="white-space:nowrap;">#formatMinutes(e.minutes)#</span>
                            <cfif e.sessions GT 1>
                                <span style="white-space:nowrap;color:##6b7280;" title="#e.sessions# sessions merged">&times;#e.sessions#</span>
                            </cfif>
                        </cfif>
                        <cfif IsObject(e.task) AND Len(e.task.workItemId ?: "")>
                            <span style="white-space:nowrap;color:##374151;">Task #e.task.workItemId#</span>
                        </cfif>
                        <cfif IsObject(e.task) AND Len(e.task.url ?: "")>
                            <a href="#encodeForHtmlAttribute(e.task.cardUrl())#" target="_blank" rel="noopener" style="white-space:nowrap;">Open card &##8599;</a>
                        </cfif>
                    </div>
                    <cfif Len(e.notes)>
                        <div style="color:##4b5563;margin-top:.15rem;">#encodeForHtml(e.notes)#</div>
                    </cfif>
                </div>
            </cfloop>
        </div>
    </cfloop>

    <cfif showTimes>
        <div style="border-top:2px solid ##111;padding-top:.5rem;font-size:1.15rem;">
            <strong>Day total:</strong> <strong>#formatMinutes(grandTotalMinutes)#</strong>
            <cfif NOT includeExcluded><small style="color:##6b7280;">(billable only)</small></cfif>
        </div>
    </cfif>
<cfelse>
    <p>No <cfif NOT includeExcluded>billable </cfif>entries for this day.</p>
</cfif>

<cfif hiddenCount GT 0 AND NOT includeExcluded>
    <p><small style="color:##6b7280;">#hiddenCount# personal/non-billable #(hiddenCount EQ 1 ? "entry" : "entries")# hidden &mdash; tick the box above to include #(hiddenCount EQ 1 ? "it" : "them")#.</small></p>
</cfif>
</cfoutput>
