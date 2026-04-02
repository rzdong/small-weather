package handlers

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetCities(c *gin.Context) {
	userID := c.GetInt("userID")

	rows, err := DB.Query("SELECT city_id, city_name, lat, lon FROM user_cities WHERE user_id = ?", userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}
	defer rows.Close()

	cities := []City{}
	for rows.Next() {
		var city City
		if err := rows.Scan(&city.ID, &city.Name, &city.Lat, &city.Lon); err != nil {
			log.Println("City scan error:", err)
			continue
		}
		cities = append(cities, city)
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": cities})
}

func AddCity(c *gin.Context) {
	userID := c.GetInt("userID")
	var newCity City
	if err := c.ShouldBindJSON(&newCity); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid payload"})
		return
	}

	var userExists int
	err := DB.QueryRow("SELECT COUNT(*) FROM users WHERE id = ?", userID).Scan(&userExists)
	if err != nil {
		log.Println("Check user exists DB error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}
	if userExists == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "User session is invalid, please log in again"})
		return
	}

	var existingID int
	err = DB.QueryRow(
		"SELECT id FROM user_cities WHERE user_id = ? AND city_id = ? LIMIT 1",
		userID,
		newCity.ID,
	).Scan(&existingID)
	if err == nil {
		GetCities(c)
		return
	}
	if err != sql.ErrNoRows {
		log.Println("Check existing city DB error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	_, err = DB.Exec(
		"INSERT INTO user_cities (user_id, city_id, city_name, lat, lon) VALUES (?, ?, ?, ?, ?)",
		userID,
		newCity.ID,
		newCity.Name,
		newCity.Lat,
		newCity.Lon,
	)
	if err != nil {
		log.Println("Add city DB error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "City already added or DB error"})
		return
	}

	// Fetch updated list
	GetCities(c)
}

func DeleteCity(c *gin.Context) {
	userID := c.GetInt("userID")
	id := c.Param("id")

	_, err := DB.Exec("DELETE FROM user_cities WHERE user_id = ? AND city_id = ?", userID, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	GetCities(c)
}

// User Settings
func GetSettings(c *gin.Context) {
	userID := c.GetInt("userID")
	var u UserPreferences
	err := DB.QueryRow("SELECT language, is_dark_mode, light_angle, shadow_intensity FROM user_settings WHERE user_id = ?", userID).Scan(&u.Language, &u.IsDarkMode, &u.LightAngle, &u.ShadowIntensity)
	if err != nil {
		if err == sql.ErrNoRows {
			// No settings found, maybe return default?
			c.JSON(http.StatusOK, gin.H{"success": true, "data": UserPreferences{Language: "en", IsDarkMode: false, LightAngle: -2.356, ShadowIntensity: 1.0}})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error fetching settings"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": u})
}

func UpdateSettings(c *gin.Context) {
	userID := c.GetInt("userID")
	var u UserPreferences
	if err := c.ShouldBindJSON(&u); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid settings payload"})
		return
	}

	_, err := DB.Exec("INSERT INTO user_settings (user_id, language, is_dark_mode, light_angle, shadow_intensity) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE language = VALUES(language), is_dark_mode = VALUES(is_dark_mode), light_angle = VALUES(light_angle), shadow_intensity = VALUES(shadow_intensity)", userID, u.Language, u.IsDarkMode, u.LightAngle, u.ShadowIntensity)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error saving settings"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Settings updated"})
}
