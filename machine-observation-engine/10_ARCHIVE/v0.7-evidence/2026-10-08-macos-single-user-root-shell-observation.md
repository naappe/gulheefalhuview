# macOS Single-User Root Shell Observation — 2026-10-08

## Scope
User-observed boot transcript from a Mac/BSD-style single-user environment. This record aligns the observation with the Machine Observation Engine evidence model. It does not infer success for commands whose results were not observed.

## Raw observed transcript

```text
BSD root: disk1, major 1, minor 4
ioqueue_depth = 128, ioscale = 4

Kernel is LP64

[1] has started up in single-user mode.
Verbose boot, will log to /dev/console.
Shutdown logging is enabled.

Singleuser boot — fsck not done
Root device is mounted read-only

If you want to make modifications to files:
    /sbin/fsck -fy
    /sbin/mount -uw /

If you wish to boot the system:
    exit

:/ root# /sbin/mount -uw
```

## Evidence classification

### OBSERVED_BOOT
- BSD root device reported as disk1, major 1, minor 4.
- ioqueue_depth = 128.
- ioscale = 4.
- kernel reports LP64.
- startup reports single-user mode.
- verbose boot logging reports /dev/console.
- shutdown logging reports enabled.

### OBSERVED_FILESYSTEM_STATE
Before the entered mount command:
- fsck reports not done.
- root device reports mounted read-only.

### OBSERVED_INSTRUCTIONS
The environment itself displayed:
- `/sbin/fsck -fy`
- `/sbin/mount -uw /`
- `exit`

These are displayed recovery/boot instructions, not evidence that the commands were executed successfully.

### OBSERVED_SHELL_CONTEXT
Prompt:
```text
:/ root#
```

This supports that an interactive shell is presenting a root/privileged prompt in the single-user environment.

It does NOT mean the shell is the kernel.

### COMMAND_ENTERED
Observed command:
```text
/sbin/mount -uw
```

The transcript supplied does not include the trailing `/` shown by the environment's own instruction.

No command result is present after this line.

Therefore:
- command entry = OBSERVED
- command success = UNKNOWN
- root filesystem changed to read-write = UNKNOWN

A later observation such as mount output/state or a successful controlled write would be required to promote the state transition to observed/correlated evidence.

## Correct architecture

```text
keyboard / console
       |
       v
root shell process
       |
       | system calls / exec
       v
kernel
       |
       +--> VFS / mount subsystem
       |        |
       |        v
       |    filesystem
       |        |
       |        v
       |    block device
       |
       +--> process / memory / device subsystems
```

The root shell is a user-space command interpreter with privileged credentials. It parses the typed command and starts or invokes programs. The kernel remains the authority that services system calls and enforces filesystem/device/process semantics.

## Meaning of the visible layers

```text
BOOT / KERNEL
  "Kernel is LP64"
  "BSD root: disk1..."
        |
        v
FILESYSTEM / MOUNT STATE
  root device mounted read-only
  fsck not done
        |
        v
USER-SPACE RECOVERY ENVIRONMENT
  single-user startup
        |
        v
ROOT SHELL
  :/ root#
        |
        v
COMMAND
  /sbin/mount -uw
        |
        v
REQUEST TO KERNEL
  mount/remount operation
        |
        v
RESULTING STATE
  UNKNOWN in supplied transcript
```

## Machine Observation Engine alignment

This observation suggests a new Unix/macOS boot sensor domain:

### boot_sensor
Potential fields:
- timestamp
- platform
- boot_mode
- kernel_architecture
- root_device
- device_major
- device_minor
- console
- verbose_boot
- evidence_class

### filesystem_state_sensor
Potential fields:
- mount_point
- device
- filesystem
- mount_flags
- writable
- fsck_state
- observed_at
- sensor
- evidence_class

### shell_context_sensor
Potential fields:
- tty_or_console
- uid
- effective_uid
- shell
- cwd
- prompt_context
- single_user_mode
- observed_at
- evidence_class

### command_event
Potential fields:
- command_text
- executable
- arguments
- entered_at
- process_instance_id
- effective_uid
- result_known
- exit_code
- evidence_class

## Correlation model

```text
BOOT_MODE(single-user)
        |
        +--> ROOT_DEVICE(disk1)
        |       |
        |       +--> MOUNT_STATE(read-only)
        |
        +--> SHELL_CONTEXT(root prompt)
                |
                +--> COMMAND_ENTERED(/sbin/mount -uw)
                        |
                        +--> STATE_TRANSITION(?)
                                  |
                                  +--> UNKNOWN until verified
```

## Evidence invariant
A displayed instruction is not an executed command.
A typed command is not a successful operation.
A root shell is not the kernel.
Privilege changes what the kernel may authorize; it does not remove the kernel from the control path.
A read-only filesystem must not be labeled read-write until a later observation proves the transition.

## Next useful observation
After a mount/remount command, capture the resulting mount state and command exit status. That allows the engine to represent:

```text
READ_ONLY --[command entered]--> TRANSITION_REQUESTED
TRANSITION_REQUESTED --[verified mount state]--> READ_WRITE
```

without manufacturing the second transition when its evidence is absent.
