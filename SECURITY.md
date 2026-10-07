# Security policy

Please report vulnerabilities privately through GitHub's security-advisory
feature instead of opening a public issue. Include the affected version, a
minimal reproduction and the expected impact.

Nocturne does not need root for its normal shell. System-wide helpers use
`pkexec`, are kept separate from the user installer, and should be reviewed
before approval. The repository must never contain credentials or machine
backups.

The Community edition must not gain a telemetry URL, hidden install identifier
or analytics client. Distribution analytics belong to the private Operator
deployment described in `PRIVACY.md`. Continuity identities are credentials:
keep them mode `0600`, never commit them and transfer them out-of-band.
