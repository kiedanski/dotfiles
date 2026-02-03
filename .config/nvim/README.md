

# Python

If using `uv` and python does not pick up the environment you can use:

```json
{
  "venvPath": ".",
  "venv": ".venv",
  "typeCheckingMode": "basic",
  "useLibraryCodeForTypes": true,
  "autoSearchPaths": true
}
```

and save it as `pyrightconfig.json` at the root of the repo in which you are working
