# Security policy

Please report vulnerabilities privately through GitHub's security-advisory
feature instead of opening a public issue. Include the affected version, a
minimal reproduction and the expected impact.

Nocturne does not need root for its normal shell. System-wide helpers use
`pkexec`, are kept separate from the user installer, and should be reviewed
before approval. The repository must never contain credentials or machine
backups.
