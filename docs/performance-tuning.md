# Performance Tuning Notes

Changes made for midrange CPU stutter when every skeleton is active. These are intentionally small and reversible.

## May 10 2026 Skeleton Crowd Tuning

- Level skeleton counts in `scripts/core/level_state.gd` were reduced to `12` per level. Original values were `20`, `20`, `18`, and `20`.
- Level spawn intervals in `scripts/core/level_state.gd` were increased to `0.9`. Original values were `0.6`, `0.55`, `0.6`, and `0.6`.
- Rescue requirements in `scripts/core/level_state.gd` were lowered to keep the 12-skeleton levels completable. Original values were `16`, `14`, `15`, and `16`.
- `WALK_SPEED` in `scripts/minions/skeleton_minion.gd` was reduced to `34.0`. Original value was `42.0`.
- `WALK_ANIM_FPS` in `scripts/minions/skeleton_minion.gd` was reduced to `10.0`. Original value was `14.0`.
- Skeleton visual redraws now batch through `VISUAL_REDRAW_FPS` at `24.0` while onscreen and `OFFSCREEN_REDRAW_FPS` at `8.0` while offscreen. Revert by replacing `_request_visual_redraw(...)` calls with `queue_redraw()` and removing the `VisibleOnScreenNotifier2D` child.
- Blocker lookahead in `scripts/minions/skeleton_minion.gd` now caches results for `BLOCKER_CHECK_INTERVAL` at `0.08` seconds. Revert by changing `_has_blocker_ahead(delta)` back to an uncached per-physics-frame check.
- Bone splash effects in `scripts/effects/bone_splash.gd` were reduced to `6` fragments, `3` ripples, and `5` goop jets. Original values were `10`, `5`, and `8`.
- Bone splash redraws now cap at `REDRAW_FPS` of `30.0` instead of redrawing every frame.
- A lightweight `F4` perf overlay in `scripts/ui/game_ui.gd` shows FPS, active skeletons, spawned skeletons, and node count. It is hidden by default.

## Retest Focus

- Watch for visible choppiness in walking legs from lower `WALK_ANIM_FPS` or redraw batching.
- Verify blockers still turn nearby skeletons reliably; if not, lower `BLOCKER_CHECK_INTERVAL` to `0.04` or revert that cache.
- Verify water death splashes still read well enough with fewer particles.
