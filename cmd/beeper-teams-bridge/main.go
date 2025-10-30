package main

import (
	"fmt"
	"os"
)

// Information to find out exactly which commit the bridge was built from.
// These are filled at build time with the -X linker flag.
var (
	Tag       = "unknown"
	Commit    = "unknown"
	BuildTime = "unknown"
)

// Bridge version information
var (
	Name    = "beeper-teams-bridge"
	URL     = "https://github.com/lqdev/beeper-teams-bridge"
	Version = "0.1.0"
)

func main() {
	if len(os.Args) > 1 && (os.Args[1] == "-v" || os.Args[1] == "--version") {
		fmt.Printf("%s %s (%s)\n", Name, Version, Tag)
		fmt.Printf("Built from commit %s at %s\n", Commit, BuildTime)
		fmt.Printf("Project URL: %s\n", URL)
		os.Exit(0)
	}

	fmt.Printf("%s v%s starting...\n", Name, Version)
	fmt.Println("This is a placeholder implementation.")
	fmt.Println("The bridge framework will be implemented in future updates.")
	fmt.Println()
	fmt.Println("For more information, see:")
	fmt.Println("  - README.md for setup instructions")
	fmt.Println("  - CONTRIBUTING.md for development guidelines")
	fmt.Println("  - example-config.yaml for configuration options")
}
