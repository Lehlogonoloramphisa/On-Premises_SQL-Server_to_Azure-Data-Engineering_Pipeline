# Databricks notebook startup

## Run order

1. Run `01_Bronze_Validation.ipynb` to confirm access to the Bronze container and expected source folders.
2. Run `02_Silver_Transformations.ipynb` after the ADF loads have completed.
3. Run `03_Gold_Analytics.ipynb` after the Silver Delta tables exist.

## Common failures

- **ADLS access or path errors:** verify the workspace identity has storage data access and that the configured account/container and entity folder names match the deployment.
- **Missing Silver/Gold catalog or schema:** provision `adb_adventureworks_dev` and grant the notebook identity permission to create/use the `silver` and `gold` schemas.
- **Missing Bronze files:** run the ADF pipeline and confirm its sink path and watermark rows before starting Silver.
- **Missing table or dataframe:** use the new layer-specific notebooks in order; they load their own layer inputs rather than depending on state left by another notebook session.

These notebooks have not been run against Azure services from this local workspace.
