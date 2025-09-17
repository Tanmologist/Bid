--[[
All folders under this file will be flattened after mirroring to make referencing easier.
Folders' mere purpose is organization
Mirroring have to be edited in config.project.json after new scripts are added

generate the new mirror paths using the commandline below:


Get-ChildItem -Recurse -Filter *.luau Modules | ForEach-Object {
  $name = $_.BaseName
  $path = $_.FullName.Replace((Get-Location).Path + '\', '').Replace('\', '/')
  Write-Output "    `"$name`": { `"`$path`": `"$path`" },"
}

]]