package main

import (
	"log"
	"weather-service/handlers"
	"weather-service/middleware"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	/** 加载env文件到运行的环境变量中 */
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, it is fine.")
	}
	handlers.InitDB()

	r := gin.Default()
	r.Use(cors.Default())
	r.Use(middleware.RequestLogger())

	api := r.Group("/api")
	{
		// Auth
		auth := api.Group("/auth")
		{
			auth.POST("/login", handlers.Login)
			auth.POST("/register/send-code", handlers.SendRegisterCode)
			auth.POST("/register", handlers.Register)
			auth.POST("/reset-password/send-code", handlers.SendResetPasswordCode)
			auth.POST("/reset-password/verify-code", handlers.VerifyResetPasswordCode)
			auth.POST("/reset-password", handlers.ResetPassword)
			auth.POST("/logout", middleware.RequireAuth(), handlers.Logout)
		}

		// User Cities
		user := api.Group("/user")
		user.Use(middleware.RequireAuth())
		{
			user.GET("/cities", handlers.GetCities)
			user.POST("/cities", handlers.AddCity)
			user.DELETE("/cities/:id", handlers.DeleteCity)
			user.GET("/settings", handlers.GetSettings)
			user.POST("/settings", handlers.UpdateSettings)
			user.GET("/profile", handlers.GetProfile)
			user.PUT("/profile", handlers.UpdateProfile)
			user.GET("/avatar/sts", handlers.GetAvatarUploadSTS)
		}

		// Weather Proxies
		weather := api.Group("/weather")
		{
			weather.GET("/geo/lookup", handlers.GeoLookup)
			weather.GET("/geo/top", handlers.GeoTop)
			weather.GET("/now", handlers.WeatherNow)
			weather.GET("/24h", handlers.Weather24h)
			weather.GET("/7d", handlers.Weather7d)
		}
	}

	log.Println("Go Server started on http://localhost:3001")
	r.Run(":3001")
}
