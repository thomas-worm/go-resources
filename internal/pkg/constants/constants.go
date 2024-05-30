package constants

import (
	goversion "github.com/hashicorp/go-version"
)

var (
	branch  string
	commit  string
	version string
)

// Gets the source repository branch.
//
// @return branchName The Branch name.
func GetBranch() (branchName string) {
	return branch
}

// Gets the source code commit hash.
//
// @return commitHash The commit hash.
func GetCommit() (commitHash string) {
	return commit
}

// Gets the current version
//
// @return versionInfo The version.
func GetVersion() (versionInfo goversion.Version) {
	parsedVersion, error := goversion.NewVersion(version)
	if error == nil {
		return *parsedVersion
	}
	return nil
}

