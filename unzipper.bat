@echo off
for %%z in (*.zip) do (
	powershell.exe Expand-Archive -LiteralPath %%z -Force
	del %%z
)