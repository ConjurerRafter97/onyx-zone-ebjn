
-- Resolved chain (all verified live via curl):
--   rscripts raw -> https://raw.githubusercontent.com/myheisenberg/Ragdoll-Playground/main/nokey.luau
--   -> https://raw.githubusercontent.com/myheisenberg/Zynex-Hub/main/loader.luau
--   -> https://raw.githubusercontent.com/myheisenberg/Zynex-Hub/main/main.luau (game table + keyless launch)
loadstring(game:HttpGet("https://raw.githubusercontent.com/myheisenberg/Zynex-Hub/main/main.luau"))()
