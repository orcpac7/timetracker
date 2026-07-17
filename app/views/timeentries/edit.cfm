<cfoutput>
<h1>Edit time entry</h1>
#errorMessagesFor("timeEntry")#

<cfset startVal = dateFormat(timeEntry.startedAt, "yyyy-mm-dd") & "T" & timeFormat(timeEntry.startedAt, "HH:mm")>
<cfset endVal = Len(timeEntry.endedAt ?: "") ? dateFormat(timeEntry.endedAt, "yyyy-mm-dd") & "T" & timeFormat(timeEntry.endedAt, "HH:mm") : "">

#startFormTag(route="updateTimeEntry", key=timeEntry.id, method="post")#
    <div class="field">
        <label for="startedAt">Start</label>
        <input type="datetime-local" name="startedAt" id="startedAt" step="60" value="#startVal#">
    </div>
    <div class="field">
        <label for="endedAt">End</label>
        <input type="datetime-local" name="endedAt" id="endedAt" step="60" value="#endVal#">
    </div>
    <div class="field">
        <label for="notes">Notes</label>
        <input type="text" name="notes" id="notes" style="width:100%;" value="#encodeForHtmlAttribute(timeEntry.notes ?: '')#">
    </div>
    #submitTag(value="Save changes")#
#endFormTag()#

<p>#linkTo(text="Back to dashboard", controller="timeEntries", action="index")#</p>
</cfoutput>
