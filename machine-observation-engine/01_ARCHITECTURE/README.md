# 01 — Architecture

Defines system boundaries, invariants and the canonical data flow.

Pipeline:

`Sensors -> Normalizer -> Correlator -> Evidence Store -> Reasoner -> Human Meaning`

## Core invariant

The Reasoner may interpret evidence, but it must never manufacture evidence.
