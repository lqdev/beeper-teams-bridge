package main

import (
	"testing"
)

// TestVersion verifies version information is set correctly
func TestVersion(t *testing.T) {
	if Name == "" {
		t.Error("Name should not be empty")
	}
	if Version == "" {
		t.Error("Version should not be empty")
	}
	if URL == "" {
		t.Error("URL should not be empty")
	}

	expectedName := "mautrix-teams"
	if Name != expectedName {
		t.Errorf("Expected name to be %s, got %s", expectedName, Name)
	}

	expectedVersion := "0.1.0"
	if Version != expectedVersion {
		t.Errorf("Expected version to be %s, got %s", expectedVersion, Version)
	}
}

// TestBuildInfo verifies build information variables exist
func TestBuildInfo(t *testing.T) {
	// These are set at build time, so we just verify they exist
	// and are not nil
	_ = Tag
	_ = Commit
	_ = BuildTime
}
