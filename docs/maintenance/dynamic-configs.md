# Dynamic application configuration

Some applications rewrite their configuration while they are running. The
following files remain in the repository as reviewed reference snapshots, but
are excluded from automatic chezmoi deployment and status checks:

- VS Code and VSCodium user settings
- Fcitx5 input method preferences and profile
- illogical-impulse settings

This prevents application generated state from repeatedly dirtying the
chezmoi working tree and prevents a restore from overwriting local changes.

When intentionally changing one of these configurations:

1. Close the application so it has flushed its settings.
2. Compare the live file with the repository reference.
3. Copy only deliberate personal changes into the reference file.
4. Review the Git diff and commit it separately from normal dotfile changes.

The ignored live files are still present on the machine and are not deleted by
`chezmoi apply`. A fresh installation should create them through the relevant
application or by manually copying the reviewed reference after the first
launch.
