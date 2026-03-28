package handlers

import (
	"database/sql"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

type User struct {
	ID       int
	Email    string
	Password string
	Name     string
	Avatar   string
}

type City struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Lat  string `json:"lat"`
	Lon  string `json:"lon"`
}

type UserPreferences struct {
	Language        string  `json:"language"`
	IsDarkMode      bool    `json:"is_dark_mode"`
	LightAngle      float64 `json:"light_angle"`
	ShadowIntensity float64 `json:"shadow_intensity"`
}

func InitDB() {
	var err error
	// Use utf8mb4 explicitly so Chinese city names and user data can be stored safely.
	DB, err = sql.Open(
		"mysql",
		"root:Rzdong123456@(127.0.0.1:3306)/weather-app?parseTime=true&charset=utf8mb4&collation=utf8mb4_unicode_ci",
	)
	if err != nil {
		log.Fatalf("Error opening MySQL: %v", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatalf("Error connecting to MySQL: %v", err)
	}

	ensureSchema()
	log.Println("MySQL Connection established.")
}

func ensureSchema() {
	if _, err := DB.Exec(`
		ALTER TABLE users
		ADD COLUMN IF NOT EXISTS user_avatar VARCHAR(255) NULL AFTER name
	`); err != nil {
		log.Printf("ensure users.user_avatar column error: %v", err)
	}

	if _, err := DB.Exec(`
		ALTER TABLE users
		CONVERT TO CHARACTER SET utf8mb4
		COLLATE utf8mb4_unicode_ci
	`); err != nil {
		log.Printf("ensure users charset error: %v", err)
	}

	if _, err := DB.Exec(`
		ALTER TABLE user_cities
		CONVERT TO CHARACTER SET utf8mb4
		COLLATE utf8mb4_unicode_ci
	`); err != nil {
		log.Printf("ensure user_cities charset error: %v", err)
	}

	if _, err := DB.Exec(`
		ALTER TABLE verification_codes
		CONVERT TO CHARACTER SET utf8mb4
		COLLATE utf8mb4_unicode_ci
	`); err != nil {
		log.Printf("ensure verification_codes charset error: %v", err)
	}
}
