class_name M7Playthrough
extends RefCounted

const GameRuntimeScript = preload("res://src/gameplay/game_runtime.gd")
const DamagePipelineScript = preload("res://src/gameplay/combat/damage_pipeline.gd")

var seed_value := 424242
var log_lines: PackedStringArray = []

func execute() -> Dictionary:
    var runtime := GameRuntimeScript.new()
    var errors := runtime.initialize(seed_value)
    if not errors.is_empty(): return {"ok": false, "error": "initialize: %s" % "; ".join(errors), "log": log_lines}
    log_lines.append("seed=%d wave=1 life=%d" % [seed_value, runtime.player_state.lives])
    var wave_guard := 0
    while runtime.outcome_state == "playing" and wave_guard < 60:
        wave_guard += 1
        if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
            if not _complete_construction(runtime):
                return {"ok": false, "error": "construction blocked at wave %d" % runtime.phases.wave_number, "log": log_lines}
        var guard := 0
        while runtime.wave.is_active() and guard < 240:
            runtime.tick(1.0)
            for enemy: EnemyRuntime in runtime.combat.enemies:
                if enemy.is_alive():
                    var context := DamagePipelineScript.DamageContext.new()
                    context.base_damage = 1000000000.0
                    context.damage_type = DamagePipelineScript.DamageType.PURE
                    var result := DamagePipelineScript.resolve(context, enemy)
                    enemy.apply_damage(result)
            guard += 1
        if runtime.wave.is_active():
            log_lines.append("stalled pending=%d alive=%d resolved=%d enemies=%d phase=%s" % [runtime.wave.pending, runtime.wave.alive, runtime.wave.resolved, runtime.combat.enemies.size(), runtime.phases.phase])
            return {"ok": false, "error": "wave %d did not resolve" % runtime.phases.wave_number, "log": log_lines}
        if runtime.outcome_state == "playing" and not runtime.support_rewards.candidates.is_empty():
            runtime.support_rewards.choose(runtime.support_rewards.candidates[0])
        log_lines.append("wave=%d score=%d gold=%d xp=%d life=%d progress=%.2f" % [runtime.phases.wave_number, runtime.player_state.score, runtime.player_state.gold, runtime.player_state.xp, runtime.player_state.lives, runtime.player_state.progress])
            # Keep the deterministic log in memory; the runner reports only
            # failures so CI output remains bounded.
    if runtime.outcome_state == "playing":
        return {"ok": false, "error": "playthrough guard exceeded", "log": log_lines}
    var signature := "%s|score=%d|gold=%d|xp=%d|life=%d|wave=%d" % [runtime.outcome_state, runtime.player_state.score, runtime.player_state.gold, runtime.player_state.xp, runtime.player_state.lives, runtime.phases.wave_number]
    log_lines.append(signature)
    return {"ok": runtime.outcome_state == "victory", "signature": signature, "log": log_lines}

func _complete_construction(runtime: GameRuntime) -> bool:
    var candidates_before := runtime.construction.board_gems.size()
    for x in range(1, 35):
        for y in range(1, 35):
            if runtime.construction.placed_count() >= 5: break
            runtime.construction.place_gem(Vector2i(x, y), int(runtime.player_state.player_level))
        if runtime.construction.placed_count() >= 5: break
    if runtime.construction.placed_count() < 5: return false
    var selected: GemInstance = runtime.construction.board_gems.back()
    if runtime.construction.board_gems.size() <= candidates_before: return false
    runtime.construction.select_board_gem(selected.cell)
    return runtime.construction.keep(selected)
