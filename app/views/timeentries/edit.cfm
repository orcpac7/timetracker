<cfoutput>
<h1>Edit time entry</h1>
#errorMessagesFor("timeEntry")#

<cfset startVal = dateFormat(timeEntry.startedAt, "yyyy-mm-dd") & "T" & timeFormat(timeEntry.startedAt, "HH:mm")>
<cfset endVal = Len(timeEntry.endedAt ?: "") ? dateFormat(timeEntry.endedAt, "yyyy-mm-dd") & "T" & timeFormat(timeEntry.endedAt, "HH:mm") : "">

<cfset currentTask = false>
<cfif IsObject(timeEntry.task ?: "")>
    <cfset currentTask = timeEntry.task>
</cfif>

#startFormTag(route="updateTimeEntry", key=timeEntry.id, method="post")#
    <div class="field">
        <label for="projectCode_id">Project code</label>
        <select name="projectCode_id" id="projectCode_id">
            <option value="">-- select --</option>
            <cfloop query="projectCodes">
                <option value="#projectCodes.id#" <cfif IsObject(timeEntry) AND timeEntry.projectCode_id EQ projectCodes.id>selected</cfif>>#projectCodes.code# &ndash; #encodeForHtml(projectCodes.description)#</option>
            </cfloop>
        </select>
    </div>
    <div class="field">
        <label for="startedAt">Start</label>
        <input type="datetime-local" name="startedAt" id="startedAt" step="60" value="#startVal#">
    </div>
    <div class="field">
        <label for="endedAt">End</label>
        <input type="datetime-local" name="endedAt" id="endedAt" step="60" value="#endVal#">
    </div>
    <div class="field">
        <label for="url">Task card URL <small>(optional)</small></label>
        <input type="url" name="url" id="url" value="#encodeForHtmlAttribute(IsObject(currentTask) ? (currentTask.url ?: '') : '')#" placeholder="https://dev.azure.com/&hellip;/_workitems/edit/12345" style="width:100%;">
    </div>
    <div class="field">
        <label for="title">Title <small>(for a new card)</small></label>
        <input type="text" name="title" id="title" value="#encodeForHtmlAttribute(IsObject(currentTask) ? (currentTask.title ?: '') : '')#" style="width:100%;">
    </div>
    <div class="field">
        <label for="notes">Notes</label>
        <input type="text" name="notes" id="notes" style="width:100%;" value="#encodeForHtmlAttribute(timeEntry.notes ?: '')#">
    </div>
    #submitTag(value="Save changes")#
#endFormTag()#

<p>#linkTo(text="Back to dashboard", controller="timeEntries", action="index")#</p>
</cfoutput>
