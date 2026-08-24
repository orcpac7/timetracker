<cfoutput>
<cfset navSuffix = (includeExcluded ? "&includeExcluded=1" : "") & (showTimes ? "&showTimes=1" : "")>
<p style="float:left;">#linkTo(text="Back to Time Tracker", controller="timeEntries", action="index")#&nbsp;|&nbsp;#linkTo(text="Back to report", route="dailyReport", params="date=#reportDateStr#" & navSuffix)#&nbsp;|&nbsp;<a href="/report/daily/notes?date=#reportDateStr##navSuffix#">Notes-only version</a></p>
<h1>Daily report &mdash; email version</h1>

<p style="color:##4b5563;">
    Click <strong>Copy for email</strong>, then paste (Ctrl+V) into your Outlook message. The
    indentation and spacing are built with tables and literal spacing so they survive the paste.
</p>

#includePartial("emailCopy")#

<hr>

<!--- ===== Copyable, email-safe region (tables + inline styles only) ===== --->
<div id="emailReport">
    <div style="font-family:Calibri, Arial, sans-serif; font-size:11pt; color:##000000;">
        <div style="font-size:14pt; font-weight:bold; margin-bottom:8pt;">
            Daily report &mdash; #dateFormat(reportDateStr, "dddd, mmm d, yyyy")#
        </div>

        <cfif ArrayLen(groups)>
            <cfloop array="#groups#" index="g">
                <!--- Project code heading --->
                <div style="font-size:12pt; font-weight:bold; margin-top:12pt; margin-bottom:4pt;">
                    #g.code.code# &ndash; #encodeForHtml(g.code.description)#<cfif g.excluded> (non-billable)</cfif><cfif showTimes> &mdash; Subtotal: #formatMinutes(g.totalMinutes)#</cfif>
                </div>

                <!--- Indented entry table: spacer column + content column --->
                <table cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;">
                    <cfloop array="#g.lines#" index="e">
                        <tr>
                            <td width="30" style="width:30px;">&nbsp;</td>
                            <td style="font-size:11pt; padding-bottom:2pt;">
                                <span style="font-weight:bold;"><cfif IsObject(e.task) AND Len(e.task.title ?: "")>#encodeForHtml(e.task.title)#<cfelse>Ad-hoc</cfif></span><cfif showTimes> &mdash; #formatMinutes(e.minutes)#<cfif e.sessions GT 1> (&times;#e.sessions#)</cfif></cfif><cfif IsObject(e.task) AND Len(e.task.workItemId ?: "")> &mdash; Task #e.task.workItemId#</cfif><cfif IsObject(e.task) AND Len(e.task.url ?: "")> &mdash; <a href="#encodeForHtmlAttribute(e.task.cardUrl())#" style="color:##2563eb;">Open card</a></cfif>
                                <cfif ArrayLen(e.notes)>
                                    <cfloop array="#e.notes#" index="n"><br><span style="color:##4b5563;">#encodeForHtml(n)#</span></cfloop>
                                </cfif>
                            </td>
                        </tr>
                        <!--- Blank line after each entry (literal spacer row) --->
                        <tr><td colspan="2" style="font-size:6pt; line-height:6pt;">&nbsp;</td></tr>
                    </cfloop>
                </table>
            </cfloop>

            <cfif showTimes>
                <div style="font-size:12pt; font-weight:bold; margin-top:12pt; border-top:1px solid ##000000; padding-top:4pt;">
                    Day total: #formatMinutes(grandTotalMinutes)#<cfif NOT includeExcluded> (billable only)</cfif>
                </div>
            </cfif>
        <cfelse>
            <div>No <cfif NOT includeExcluded>billable </cfif>entries for this day.</div>
        </cfif>
    </div>
</div>
</cfoutput>
