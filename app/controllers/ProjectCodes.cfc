component extends="Controller" {

    function config() {
        super.config();
    }

    // List all billing codes.
    function index() {
        projectCodes = model("ProjectCode").findAll(order="code");
    }

    // Show the new-code form (pre-filled with sensible defaults).
    function new() {
        projectCode = model("ProjectCode").new(active=true, color="##6b7280");
    }

    // Persist a new code.
    function create() {
        projectCode = model("ProjectCode").new(params.projectCode);
        if (projectCode.save()) {
            flashInsert(success="Project code #projectCode.code# created.");
            redirectTo(controller="projectCodes", action="index");
        } else {
            renderView(action="new");
        }
    }

    // Show the edit form.
    function edit() {
        projectCode = model("ProjectCode").findByKey(params.key);
    }

    // Persist edits.
    function update() {
        projectCode = model("ProjectCode").findByKey(params.key);
        if (projectCode.update(params.projectCode)) {
            flashInsert(success="Project code #projectCode.code# updated.");
            redirectTo(controller="projectCodes", action="index");
        } else {
            renderView(action="edit");
        }
    }

    // Delete a code.
    function delete() {
        projectCode = model("ProjectCode").findByKey(params.key);
        // softDelete=false: really remove the row (see design note in ProjectCode.cfc).
        projectCode.delete(softDelete=false);
        flashInsert(success="Project code deleted.");
        redirectTo(controller="projectCodes", action="index");
    }

}
