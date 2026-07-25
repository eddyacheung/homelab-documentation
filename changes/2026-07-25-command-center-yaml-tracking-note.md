# Command Center YAML Tracking Note

**Date:** 2026-07-25

The Home Assistant Command Center project documentation and completion record were committed to GitHub.

The current production YAML remains on the Home Assistant host at:

```text
/volume1/docker/homeassistant/config/dashboards/command-center.yaml
```

A generated working copy was also retained during the session as `01-overview-v36-final-touchups.yaml`, but the full YAML was not uploaded to the repository during this documentation pass.

Until the production YAML is copied into Git, the Home Assistant host remains the source of truth for the dashboard definition. The repository documentation is the source of truth for architecture, entities, design decisions, validation, rollback, and project status.

Recommended follow-up from the local Git checkout:

```bash
mkdir -p home-assistant/dashboards
scp root@192.168.10.101:/volume1/docker/homeassistant/config/dashboards/command-center.yaml \
  home-assistant/dashboards/01-overview.yaml

git add home-assistant/dashboards/01-overview.yaml
git commit -m "Add production Command Center dashboard YAML"
git push
```

After that commit, update any documentation references that describe the repository YAML copy as already present.
