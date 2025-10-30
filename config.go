package main

// Config represents the bridge configuration
// This is a placeholder structure that will be expanded as the bridge is developed
type Config struct {
	Homeserver HomeserverConfig `yaml:"homeserver"`
	Appservice AppserviceConfig `yaml:"appservice"`
	Bridge     BridgeConfig     `yaml:"bridge"`
	Teams      TeamsConfig      `yaml:"teams"`
	Logging    LoggingConfig    `yaml:"logging"`
	Database   DatabaseConfig   `yaml:"database"`
}

// HomeserverConfig contains homeserver connection details
type HomeserverConfig struct {
	Address  string `yaml:"address"`
	Domain   string `yaml:"domain"`
	Software string `yaml:"software"`
}

// AppserviceConfig contains appservice registration details
type AppserviceConfig struct {
	Address string `yaml:"address"`
	Hostname string `yaml:"hostname"`
	Port     int    `yaml:"port"`
	ID       string `yaml:"id"`
	BotUsername     string `yaml:"bot_username"`
	BotDisplayname  string `yaml:"bot_displayname"`
	BotAvatar       string `yaml:"bot_avatar"`
	ASToken         string `yaml:"as_token"`
	HSToken         string `yaml:"hs_token"`
}

// BridgeConfig contains bridge-specific settings
type BridgeConfig struct {
	UsernameTemplate    string `yaml:"username_template"`
	DisplaynameTemplate string `yaml:"displayname_template"`

	PrivateChatPortalMeta bool `yaml:"private_chat_portal_meta"`

	StartupChatSync    int `yaml:"startup_chat_sync"`
	StartupSyncThreads int `yaml:"startup_sync_threads"`

	DeliveryReceipts bool `yaml:"delivery_receipts"`
	AllowInvites     bool `yaml:"allow_invites"`

	Permissions map[string]string `yaml:"permissions"`
}

// TeamsConfig contains Microsoft Teams integration settings
type TeamsConfig struct {
	OAuth OAuthConfig `yaml:"oauth"`
	Sync  SyncConfig  `yaml:"sync"`
}

// OAuthConfig contains OAuth2 authentication settings
type OAuthConfig struct {
	ClientID     string `yaml:"client_id"`
	ClientSecret string `yaml:"client_secret"`
	TenantID     string `yaml:"tenant_id"`
	RedirectURI  string `yaml:"redirect_uri"`
}

// SyncConfig contains synchronization settings
type SyncConfig struct {
	SyncInterval     int  `yaml:"sync_interval"`
	SyncPresence     bool `yaml:"sync_presence"`
	SyncReadReceipts bool `yaml:"sync_read_receipts"`
	SyncTyping       bool `yaml:"sync_typing"`
}

// LoggingConfig contains logging settings
type LoggingConfig struct {
	Directory       string `yaml:"directory"`
	FileLogLevel    string `yaml:"file_log_level"`
	ConsoleLogLevel string `yaml:"console_log_level"`
}

// DatabaseConfig contains database connection settings
type DatabaseConfig struct {
	Type            string `yaml:"type"`
	URI             string `yaml:"uri"`
	MaxOpenConns    int    `yaml:"max_open_conns"`
	MaxIdleConns    int    `yaml:"max_idle_conns"`
	ConnMaxIdleTime string `yaml:"conn_max_idle_time"`
	ConnMaxLifetime string `yaml:"conn_max_lifetime"`
}
