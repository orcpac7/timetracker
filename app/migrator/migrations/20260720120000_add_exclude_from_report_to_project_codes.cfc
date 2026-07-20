component extends="wheels.migrator.Migration" hint="Add excludeFromReport flag to projectCodes (non-billable: personal, breaks, meals)" {
    function up() {
        transaction {
            try {
                // NOT NULL DEFAULT 0 backfills existing codes as "included" (not excluded).
                addColumn(table="projectCodes", columnType="boolean", columnNames="excludeFromReport", default=false, allowNull=false);
            } catch (any e) {
                local.exception = e;
            }
            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }
    function down() {
        transaction {
            removeColumn(table="projectCodes", columnNames="excludeFromReport");
            transaction action="commit";
        }
    }
}
