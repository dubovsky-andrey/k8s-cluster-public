There is suspicious activity in the cluster involving one of the pods running the `httpd:2.4-alpine` image.

Falco generates frequent alerts that start with:

```text
File below a known binary directory opened for writing
```

Identify the rule causing this alert and update it as follows:

- set the rule priority to `CRITICAL`;
- set the rule output to `File below a known binary directory opened for writing (user_id=%user.uid file_updated=%fd.name command=%proc.cmdline)`;
- configure alerts to be logged to `/opt/security_incidents/alerts.log`.

Do not update the default rules file directly. Use `/etc/falco/falco_rules.local.yaml` to override.

Expected log format:

```text
<timestamp>: Critical File below a known binary directory opened for writing (user_id=0 file_updated=/bin/sleep command=tar -xmf - -C /bin)
```

After updating the rule and output configuration, reload or restart Falco so the changes take effect.

Validate your work with:

```bash
sh ~/val.sh
```
