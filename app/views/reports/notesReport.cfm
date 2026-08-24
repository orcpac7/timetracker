<cfoutput>
<cfset navSuffix = (includeExcluded ? "&includeExcluded=1" : "") & (showTimes ? "&showTimes=1" : "")>
<p style="float:left;">#linkTo(text="Back to Time Tracker", controller="timeEntries", action="index")#&nbsp;|&nbsp;<a href="/report/daily?date=#reportDateStr##navSuffix#">Back to report</a>&nbsp;|&nbsp;<a href="/report/daily/email?date=#reportDateStr##navSuffix#">Detailed email version</a></p>
<h1>Daily report &mdash; notes only</h1>

<p style="color:##4b5563;">
    Task titles for the day with their notes bulleted underneath &mdash; no project code
    headings. Click <strong>Copy for email</strong>, then paste (Ctrl+V) into Outlook.
</p>

#includePartial("emailCopy")#

<hr>

<!--- ===== Copyable, email-safe region (inline styles only) ===== --->
<div id="emailReport">
    <div style="font-family:Calibri, Arial, sans-serif; font-size:11pt; color:##000000;">
        <div style="font-size:14pt; font-weight:bold; margin-bottom:8pt;">
            Daily report &mdash; #dateFormat(reportDateStr, "dddd, mmm d, yyyy")#
        </div>

        <cfif ArrayLen(taskNoteLines)>
            <cfloop array="#taskNoteLines#" index="t">
                <!--- Task title, then that task's notes as bullets underneath. Per-note
                      times are only worth showing when a task has more than one note;
                      otherwise the bullet would just repeat the title's duration. --->
                <div style="font-size:11pt; font-weight:bold; margin-top:10pt; margin-bottom:2pt;">
                    #encodeForHtml(t.title)#<cfif showTimes> &mdash; #formatMinutes(t.minutes)#<cfif t.sessions GT 1> (&times;#t.sessions#)</cfif></cfif>
                </div>
                <ul style="margin:0 0 0 18pt; padding:0;">
                    <cfloop array="#t.notes#" index="n">
                        <li style="font-size:11pt; margin-bottom:3pt;">#encodeForHtml(n.text)#<cfif showTimes AND ArrayLen(t.notes) GT 1> &mdash; #formatMinutes(n.minutes)#</cfif></li>
                    </cfloop>
                </ul>
            </cfloop>

            <cfif showTimes>
                <div style="font-size:12pt; font-weight:bold; margin-top:12pt; border-top:1px solid ##000000; padding-top:4pt;">
                    Day total: #formatMinutes(grandTotalMinutes)#<cfif NOT includeExcluded> (billable only)</cfif>
                </div>
            </cfif>
        <cfelse>
            <div>No <cfif NOT includeExcluded>billable </cfif>notes for this day.</div>
        </cfif>
    </div>
</div>

<hr>

<!--- Page-only footnotes: deliberately outside the copyable region. --->
<cfif showTimes AND unnotedMinutes GT 0>
    <p><small style="color:##6b7280;">Heads up: #formatMinutes(unnotedMinutes)# of the day total came from entries with no notes, so it isn't represented by any bullet above (bullets account for #formatMinutes(notedMinutes)#).</small></p>
<cfelseif unnotedMinutes GT 0>
    <p><small style="color:##6b7280;">Entries with no notes were skipped &mdash; they contribute no bullets.</small></p>
</cfif>

<cfif hiddenCount GT 0 AND NOT includeExcluded>
    <p><small style="color:##6b7280;">#hiddenCount# personal/non-billable #(hiddenCount EQ 1 ? "entry" : "entries")# hidden. <a href="/report/daily/notes?date=#reportDateStr#&includeExcluded=1#(showTimes ? "&showTimes=1" : "")#">Include #(hiddenCount EQ 1 ? "it" : "them")#</a>.</small></p>
</cfif>
</cfoutput>
