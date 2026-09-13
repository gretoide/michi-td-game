class_name SeedResolver
extends RefCounted

func resolve(explicit_seed: int = -1, default_seed: int = -1) -> int:
	if explicit_seed != -1:
		return explicit_seed
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			var parsed := argument.trim_prefix("--seed=").to_int()
			return parsed
	if default_seed != -1 and default_seed != 0:
		return default_seed
	var generator := RandomNumberGenerator.new()
	generator.randomize()
	return generator.seed
