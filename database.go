package main

// Database placeholder structures for future implementation
// This file contains the core database models that will be used by the bridge

// User represents a Matrix user who has logged into Teams
type User struct {
	MXID    string
	TeamsID string
	// Additional fields will be added as the bridge is developed
}

// Portal represents a bridged Teams chat/channel
type Portal struct {
	Key  PortalKey
	MXID string
	// Additional fields will be added as the bridge is developed
}

// PortalKey uniquely identifies a portal
type PortalKey struct {
	ChatID   string
	Receiver string
}

// Puppet represents a Teams user in Matrix (ghost user)
type Puppet struct {
	TeamsID     string
	MXID        string
	Displayname string
	AvatarURL   string
	// Additional fields will be added as the bridge is developed
}
