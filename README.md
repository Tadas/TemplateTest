## TODO

	- [-] Fix zipup
	- [ ] Move to temporary location
	- [ ] Zip up
	- [ ] Remove temp

## Add submodule

```
git submodule add https://github.com/Tadas/PSKVStore Modules/PSKVStore
```


## Clone project and all submodules
```
git clone --recursive <project url>
```


## init submodules if cloned without recursive
```
git submodule update --init --recursive
```

# Devtime
Add dependencies to .\Modules\ as git submodule

# Buildtime
Get dependency versions:
	• if no local changes - write to PSDepend
	• if local changes - test if published
there CAN'T BE ANY LOCAL CHANGES ON THE BUILD SERVER!!

During build check out everything from git and zip it up (submodule commits need to be online)

# Runtime

# Reading

 * http://duffney.io/GettingStartedWithInvokeBuild
 * https://devblackops.io/building-a-simple-release-pipeline-in-powershell-using-psake-pester-and-psdeploy/#test