package middleware

import (
	"net/http"
	"strings"
	"weather-service/handlers"

	"github.com/gin-gonic/gin"
)

func RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Unauthorized, please login"})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Invalid token format"})
			return
		}

		token := parts[1]

		claims, err := handlers.ValidateJWTForMiddleware(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Token expired or invalid"})
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("userEmail", claims.UserEmail)
		c.Set("userName", claims.UserName)
		c.Next()
	}
}
