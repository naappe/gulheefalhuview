# MachineObserver Five-Agent Reasoning V0.1

Consumes a sanitized DomainInspector `report.json`.

Agents:
1. Evidence — deterministic extraction.
2. Math — candidate/cardinality analysis.
3. State — before/after state transition.
4. Skeptic — falsification and overclaim prevention.
5. Explorer — proposes the next passive/user-driven measurement.

Consensus preserves the evidence lattice:
`OBSERVED > CORRELATED > INFERRED > HYPOTHESIS > UNKNOWN`.

No LLM/API is required in V0.1. The agents are deterministic so their behavior is auditable. They do not receive or seek passwords, OTPs, cookie/token values, request bodies, or other secrets.

Run:
```powershell
python C:\MachineObserver\agents\run_agents.py "C:\MachineObserver\sessions\<session>\report.json"
```
Output: `reasoning.json` beside the report.
