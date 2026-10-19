# onprem-mongodb Terraform module

This module provisions:

- a sentinel collection to materialize the database
- a read-write MongoDB user
- an optional read-only MongoDB user
- generated passwords and connection strings

## Inputs

- `database_name`
- `rw_username`
- `ro_username`
- `create_ro_user`

## Outputs

- `database_name`
- `rw_username`
- `rw_password`
- `rw_connection_string`
- `ro_username`
- `ro_password`
- `ro_connection_string`

## Notes

The module assumes the MongoDB provider is configured by Crossplane through the Workspace `ProviderConfig`.
