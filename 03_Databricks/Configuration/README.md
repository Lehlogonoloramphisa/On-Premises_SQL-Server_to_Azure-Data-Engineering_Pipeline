# Databricks configuration

The notebooks use the project defaults: catalog `adb_adventureworks_dev`, ADLS account `awdata2022`, and container `bronze`. These values are not verified environment-independent settings.

`../Compute_Configuration/cluster-settings.json` is an exported cluster snapshot whose state was `TERMINATED`; it is not a deployment-ready cluster definition. Historical notes record Runtime 18 LTS, a single `Standard_DS3_v2` node, Photon, Standard access mode, and 10-minute auto-termination. The Databricks workspace and its Access Connector were subsequently deleted.

The DBU trial did not cover the underlying VM costs. The recorded $3 budget alert was only a notification, not a spending cap. Credentials, storage keys, and grant statements do not belong in this folder. Before running the notebooks in a target workspace, configure identity, storage access, catalog ownership, permissions, and cost controls.
