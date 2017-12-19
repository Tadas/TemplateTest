## Add submodule

```
git submodule add https://github.com/Tadas/PSKVStore Modules/PSKVStore
```


## Clone project and all submodules
```
git clone --recursive <project url>
```


## ???
```
git submodule update
```

# Dev
Add dependencies to .\Modules\ as git submodule

# Build
During build check out everything from git and zip it up (submodule commits need to be online

# Reading

 * http://duffney.io/GettingStartedWithInvokeBuild
 * https://devblackops.io/building-a-simple-release-pipeline-in-powershell-using-psake-pester-and-psdeploy/#test