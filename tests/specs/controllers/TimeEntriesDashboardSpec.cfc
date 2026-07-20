component extends="wheels.WheelsTest" {

    function run() {
        describe("Time tracker dashboard smoke tests", function() {

            beforeEach(function() {
                if (StructKeyExists(request, "test")) {
                    StructDelete(request, "test");
                }

                // Fetch-or-create: the test DB persists across runs, and ProjectCode
                // validates uniqueness of `code`, so a plain create() collides on re-run.
                local.projectCode = model("ProjectCode").findOne(where="code = 9999");
                if (!IsObject(local.projectCode)) {
                    local.projectCode = model("ProjectCode").create(
                        code = 9999,
                        description = 'Smoke test code',
                        active = 1
                    );
                }
                assert(IsObject(local.projectCode) && Len(local.projectCode.id ?: ""), "Project code available");

                local.timeEntry = model("TimeEntry").create(
                    projectCode_id = local.projectCode.id,
                    startedAt = DateAdd("n", -60, now()),
                    endedAt = now(),
                    notes = "Smoke test entry"
                );
                assert(IsObject(local.timeEntry), "Time entry created");

                params = structNew();
                params.controller = "timeEntries";
                params.action = "index";
                _controller = application.wo.controller("timeEntries", params);
            });

            it("renders the inline edit form fields on the dashboard", function() {
                _controller.$callAction(action = "index");
                actual = _controller.response();

                assert(FindNoCase('Edit</button>', actual) > 0, "Edit button is present");
                assert(FindNoCase('name="startedAt"', actual) > 0, "StartedAt field is present");
                assert(FindNoCase('name="endedAt"', actual) > 0, "EndedAt field is present");
                assert(FindNoCase('name="notes"', actual) > 0, "Notes field is present");
                assert(FindNoCase('name="projectCode_id"', actual) > 0, "Project code selector is present");
                assert(FindNoCase('name="url"', actual) > 0, "URL field is present");
            });

        });
    }

}
