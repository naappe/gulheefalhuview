# Chrome network-service PID model
Observed investigation identified PID 19964 as chrome.exe with command-line role:
--type=utility --utility-sub-type=network.mojom.NetworkService

Model consequence:
Browser request-origin PID and Windows socket-owner PID may differ.

MachineObserver now distinguishes:
EXACT_PID
PROCESS_TREE
SAME_APPLICATION
DIFFERENT_APPLICATION
UNKNOWN

Important: same executable path is SAME_APPLICATION evidence only. Parent/child ancestry must be independently observed before PROCESS_TREE is asserted.
