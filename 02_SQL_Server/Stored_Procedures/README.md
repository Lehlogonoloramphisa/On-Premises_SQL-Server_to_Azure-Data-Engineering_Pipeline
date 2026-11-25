# Stored procedure deployment

The canonical definitions for `etl.usp_InsertLoadAudit` and `etl.usp_UpdateWatermark` are in `../Database_Scripts/Project_ETL_Objects.sql`. That consolidated script remains the deployment source of truth; the procedures should only be copied here if the deployment process moves to modular scripts.

The object script creates the `etl` schema if it does not exist. Run it before `../Control_Tables/Seed_WatermarkControl.sql`.
