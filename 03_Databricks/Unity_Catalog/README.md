# Unity Catalog setup

`01_Create_Development_Schemas.sql` creates the Silver and Gold schemas in the existing `adb_adventureworks_dev` catalog. It does not create the catalog, storage credential, or external location, and it does not grant privileges.

Run it as an authorized workspace or catalog administrator. Before deployment, confirm catalog ownership, managed-storage policy, and least-privilege grants with the environment owner. Forced creation was used after Unity Catalog file events returned 403; optional file events remain unresolved.
