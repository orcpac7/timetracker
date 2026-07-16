<cfoutput>
<h1>New project code</h1>
#errorMessagesFor("projectCode")#
#startFormTag(controller="projectCodes", action="create", method="post")#
    <div class="field">#numberField(objectName="projectCode", property="code", label="Billing code")#</div>
    <div class="field">#textField(objectName="projectCode", property="description", label="Description")#</div>
    <div class="field">#colorField(objectName="projectCode", property="color", label="Color")#</div>
    <div class="field">#checkBox(objectName="projectCode", property="active", label="Active")#</div>
    #submitTag(value="Create code")#
#endFormTag()#
<p>#linkTo(text="Back to codes", controller="projectCodes", action="index")#</p>
</cfoutput>
