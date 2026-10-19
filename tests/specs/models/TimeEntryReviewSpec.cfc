component extends="wheels.WheelsTest" {

    function run() {
        describe("Code review classification and minutes", function() {

            beforeEach(function() {
                model("TimeEntry").deleteAll(where="notes = 'review-spec'", softDelete=false);
                model("Task").deleteAll(where="title LIKE 'review-spec%'", softDelete=false);

                local.codeA = model("ProjectCode").findOne(where="code = 9998");
                if (!IsObject(local.codeA)) {
                    local.codeA = model("ProjectCode").create(code=9998, description="Review spec A", active=1);
                }
                local.codeB = model("ProjectCode").findOne(where="code = 9997");
                if (!IsObject(local.codeB)) {
                    local.codeB = model("ProjectCode").create(code=9997, description="Review spec B", active=1);
                }
                codeAId = local.codeA.id;
                codeBId = local.codeB.id;
                base = CreateDateTime(2026, 1, 15, 9, 0, 0);
                prUrl = "https://dev.azure.com/org/proj/_git/repo/pullrequest/12345";
            });

            it("classifies pull request URLs as review by default", function() {
                expect(model("Task").reviewDefaultFor(prUrl)).toBeTrue();
                expect(model("Task").reviewDefaultFor("https://dev.azure.com/org/proj/_workitems/edit/1")).toBeFalse();
                expect(model("Task").reviewDefaultFor("")).toBeFalse();
            });

            it("sums completed minutes on review tasks across project codes within the range", function() {
                local.reviewA = model("Task").create(projectCode_id=codeAId, title="review-spec A", url=prUrl, isReview=1);
                local.reviewB = model("Task").create(projectCode_id=codeBId, title="review-spec B", url=prUrl, isReview=1);
                local.plain = model("Task").create(projectCode_id=codeAId, title="review-spec plain", isReview=0);

                model("TimeEntry").create(task_id=local.reviewA.id, startedAt=base, endedAt=DateAdd("n", 30, base), notes="review-spec");
                model("TimeEntry").create(task_id=local.reviewB.id, startedAt=DateAdd("h", 1, base), endedAt=DateAdd("n", 15, DateAdd("h", 1, base)), notes="review-spec");
                model("TimeEntry").create(task_id=local.reviewA.id, startedAt=DateAdd("d", 1, base), endedAt=DateAdd("n", 45, DateAdd("d", 1, base)), notes="review-spec");
                model("TimeEntry").create(task_id=local.reviewA.id, startedAt=DateAdd("h", 2, base), notes="review-spec");
                model("TimeEntry").create(task_id=local.plain.id, startedAt=base, endedAt=DateAdd("n", 60, base), notes="review-spec");

                expect(model("TimeEntry").reviewMinutesBetween("2026-01-15 00:00:00", "2026-01-16 00:00:00")).toBe(45);
                expect(model("TimeEntry").reviewMinutesBetween()).toBeGTE(90);
            });

            it("treats a URL already marked as review as a review for new tasks", function() {
                model("Task").create(projectCode_id=codeAId, title="review-spec marked", url="https://example.com/thing/1", isReview=1);
                expect(model("Task").reviewDefaultFor("https://example.com/thing/1")).toBeTrue();
            });
        });
    }

}
