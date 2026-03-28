package handlers

import (
	"io"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func proxyQWeather(c *gin.Context, path string) {
	host := "https://pf5vxbpy5n.re.qweatherapi.com"
	key := getEnv("QWEATHER_KEY", "bc55932daedd4fa9bf52eb374fc9904b")

	req, err := http.NewRequest("GET", host+path, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to create request"})
		return
	}

	q := req.URL.Query()
	for k, v := range c.Request.URL.Query() {
		q.Add(k, v[0])
	}
	q.Add("key", key)
	req.URL.RawQuery = q.Encode()

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Upstream proxy failed", "error": err.Error()})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to read upstream response"})
		return
	}
	
	// Check content encoding, but for simplicity we assume plaintext or the compressed flag in standard http handles it. Wait, the user specifically mentioned --compressed. Go's http.Client handles gzip transparently by default.
	
	c.Data(resp.StatusCode, "application/json", body)
}

func GeoLookup(c *gin.Context) {
	proxyQWeather(c, "/geo/v2/city/lookup")
}

func GeoTop(c *gin.Context) {
	if c.Query("number") == "" {
		c.Request.URL.RawQuery += "&number=20"
	}
	if c.Query("range") == "" {
		c.Request.URL.RawQuery += "&range=cn"
	}
	proxyQWeather(c, "/geo/v2/city/top")
}

func WeatherNow(c *gin.Context) {
	proxyQWeather(c, "/v7/weather/now")
}

func Weather24h(c *gin.Context) {
	proxyQWeather(c, "/v7/weather/24h")
}

func Weather7d(c *gin.Context) {
	proxyQWeather(c, "/v7/weather/7d")
}
