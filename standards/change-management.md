# Homelab Change Management Standard

Use this checklist before medium or high impact homelab changes.

## Checklist

1. Define the goal.
2. Identify what could break.
3. Create a backup.
4. Confirm the backup exists.
5. Make one change at a time.
6. Validate the service.
7. Document the final state.
8. Commit and push the documentation.

## Required Sections for Larger Projects

- Goal
- Risk level
- Expected downtime
- Backup location
- Rollback plan
- Validation steps
- Documentation updates

## Lessons Learned

The Portainer migration showed that a service can be online while management functionality is still broken.

For future Portainer changes, validate that the web UI loads, existing stacks appear, the Stack Editor opens compose files, and stack updates can be redeployed.
