package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
)

type bodyLogWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w bodyLogWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		startedAt := time.Now()

		requestBody := readRequestBody(c)
		responseBody := &bytes.Buffer{}
		writer := &bodyLogWriter{
			ResponseWriter: c.Writer,
			body:           responseBody,
		}
		c.Writer = writer

		c.Next()

		entry := map[string]any{
			"time":          startedAt.Format(time.RFC3339),
			"method":        c.Request.Method,
			"path":          c.Request.URL.Path,
			"query":         c.Request.URL.RawQuery,
			"client_ip":     c.ClientIP(),
			"status":        c.Writer.Status(),
			"latency_ms":    time.Since(startedAt).Milliseconds(),
			"request_body":  requestBody,
			"response_body": responseBody.String(),
		}

		if userID, exists := c.Get("userID"); exists {
			entry["user_id"] = userID
		}
		if userEmail, exists := c.Get("userEmail"); exists {
			entry["user_email"] = userEmail
		}

		if len(c.Errors) > 0 {
			entry["errors"] = c.Errors.String()
		}

		writeRequestLog(entry)
	}
}

func readRequestBody(c *gin.Context) string {
	if c.Request == nil || c.Request.Body == nil {
		return ""
	}

	bodyBytes, err := io.ReadAll(c.Request.Body)
	if err != nil {
		return ""
	}
	c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
	return string(bodyBytes)
}

func writeRequestLog(entry map[string]any) {
	if err := os.MkdirAll("logs", 0o755); err != nil {
		return
	}

	payload, err := json.Marshal(entry)
	if err != nil {
		return
	}

	logPath := filepath.Join("logs", time.Now().Format("2006-01-02")+".log")
	file, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return
	}
	defer file.Close()

	_, _ = file.Write(append(payload, '\n'))
}
