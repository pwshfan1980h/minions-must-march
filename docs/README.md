# Minions Must March - Design Docs

A doc-driven planning folder for building **Minions Must March**, a Lemmings-inspired puzzle game about little lanky skeleton minions marching through spooky ruins and bone-strewn underground paths.

## Core Docs

- [Project Plan](./project-plan.md) - phased rollout, scope, milestones, and testing gates
- [Mechanics Spec](./mechanics-spec.md) - core rules, skeleton minions, jobs, hazards, and interaction model
- [Asset & Sizing Plan](./asset-sizing-plan.md) - proposed resolution, tile sizes, skeleton visual direction, SVG/procgen strategy
- [Starter Levels](./starter-levels.md) - first three puzzle designs, with Level 1 prioritized for polish
- [Tech Stack Decision](./tech-stack-options.md) - Godot 4, web export, and destructible terrain architecture notes
- [Progress Log](./progress-log.md) - durable implementation notes across sessions


## Current Design Delta

The current prototype direction has shifted from generic early hazards toward a clearer underworld identity:

- Level 1 bottom failure boundary is **River Styx-style underworld water**, not spikes.
- The crypt backdrop is currently procedural: dark gradient, faint glow, low dust/fog, animated water, and pale souls.
- Skeleton water deaths preserve the bone-splash gag, then fade/sink using an explicit `styx_water` death kind.
- Near-term design work should keep this mood while adding Builder and making Level 1 solvable.

## Working Principle

Build from docs, update docs as reality changes, and keep chat summaries concise.
