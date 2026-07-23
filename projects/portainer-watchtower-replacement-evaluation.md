# Portainer and Watchtower Replacement Evaluation

**Status:** Planned

## Goal

Evaluate replacing Portainer and Watchtower with a Compose-first Docker management platform that makes stack maintenance, updates, rollback, and Git-backed operations easier.

## Candidates

1. **Dockhand** as the primary candidate because it may cover both stack management and controlled update scheduling.
2. **Dockge** as the simpler fallback if Dockhand proves too complex or immature for this environment.

## Desired End State

- GitHub remains the source of truth for Compose files and documentation.
- Docker stacks are easy to inspect, edit, pull, redeploy, and roll back from a web interface.
- Image updates are controlled by stack and maintenance policy rather than broad unattended scanning.
- Portainer is removed only after feature parity and recovery procedures are validated.
- Watchtower is disabled and later removed only after the replacement update workflow succeeds through multiple test cycles.

## Evaluation Criteria

- Import and manage existing Compose stacks without changing persistent data paths.
- Preserve external networks such as `media-net` and service-specific networks.
- Support Git-backed or filesystem-backed Compose definitions cleanly.
- Provide clear image-update visibility and controlled pull/redeploy actions.
- Support scheduled updates or an equivalent maintenance workflow.
- Make logs, terminal access, container health, networks, volumes, and stack status easy to inspect.
- Provide straightforward backup, restore, and rollback procedures.
- Avoid breaking Gluetun-dependent services, databases, Home Assistant, TeslaMate, Plex, or other stateful services.

## Migration Plan

1. Capture the current Portainer and Watchtower configuration and confirm backups are current.
2. Deploy Dockhand alongside Portainer without changing existing stacks.
3. Import or recreate one low-risk stateless stack for testing.
4. Validate Compose rendering, start, stop, pull, recreate, logs, terminal access, and rollback.
5. Test controlled image updates on a safe opt-in container.
6. Compare Dockhand against Dockge if any required capability is missing or unreliable.
7. Migrate additional noncritical stacks in small batches.
8. Migrate stateful and dependency-sensitive stacks only after backup and rollback testing.
9. Disable Watchtower and observe at least two planned update cycles.
10. Remove Watchtower after the replacement workflow is proven.
11. Remove Portainer only after all stacks, recovery procedures, and operational documentation are validated.

## Safety Rules

- Run the new manager side by side with Portainer during evaluation.
- Do not let two tools simultaneously manage or redeploy the same stack.
- Do not enable unrestricted automatic updates for databases or critical stateful services.
- Keep tested Compose files and `.env.example` files in Git before migration.
- Back up stateful services before changing ownership or deployment method.
- Validate container health, networks, published ports, mounts, and application behavior after every migration batch.

## Completion Criteria

- A preferred platform is selected with the decision and tradeoffs documented.
- All required stack-management operations are validated.
- Controlled updates work without Watchtower.
- All existing services remain healthy and retain their data.
- Backup and rollback procedures are tested.
- Portainer and Watchtower are removed or intentionally retained with a documented reason.
- The repository, architecture map, service documentation, and project dashboard reflect the final state.
