# Troubleshooting log

## Evidence status

The resolutions below were recorded while working on the project. Supporting incident logs and screenshots were not available for this review.

| Issue | Recorded resolution | Follow-up / caveat |
|---|---|---|
| Docker API connection failure | Docker Desktop and WSL2 setup corrected | Recheck Docker and WSL2 health if local SQL containers fail to start. |
| SQL Server linked service | SHIR connection configured and tested | Confirm the SHIR host remains online and registered in the target environment. |
| ADLS authentication | Managed identity and Storage Blob Data Contributor configured | Revalidate identity, role scope, and access after environment rebuilds. |
| Unity Catalog file-events 403 | Forced creation used | Optional file events remained unresolved; do not treat them as enabled. |
| `input_file_name()` unsupported | Replaced with `_metadata.file_path` | Existing notebooks use the metadata column approach. |
| SQL backup access denied | Docker backup-directory permissions corrected | Recheck host/container path permissions if backup restore fails. |
| Windows backup path incorrect | Destination corrected and backup copied | Verify the resolved destination before future restore operations. |

These are the outcomes recorded at the time; recheck the configuration when rebuilding the environment.
