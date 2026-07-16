<cfoutput>
<h1>Project codes</h1>
<p>#linkTo(text="+ New code", controller="projectCodes", action="new")#</p>

<cfif projectCodes.recordCount>
<table>
    <thead>
        <tr><th>Code</th><th>Description</th><th>Color</th><th>Active</th><th></th></tr>
    </thead>
    <tbody>
        <cfloop query="projectCodes">
        <tr>
            <td>#projectCodes.code#</td>
            <td>#projectCodes.description#</td>
            <td>
                <span style="display:inline-block;width:1rem;height:1rem;border-radius:3px;vertical-align:middle;background:#projectCodes.color#;"></span>
                #projectCodes.color#
            </td>
            <td><cfif projectCodes.active>Yes<cfelse>No</cfif></td>
            <td style="white-space:nowrap;">
                #linkTo(text="✏ Edit", controller="projectCodes", action="edit", key=projectCodes.id)#
                &nbsp;&nbsp;
                #startFormTag(controller="projectCodes", action="delete", key=projectCodes.id, method="delete", prepend="<span style='display:inline-block'>", append="</span>")##submitTag(value="Delete")##endFormTag()#
            </td>
        </tr>
        </cfloop>
    </tbody>
</table>
<cfelse>
<p>No project codes yet. #linkTo(text="Add the first one", controller="projectCodes", action="new")#.</p>
</cfif>
</cfoutput>
