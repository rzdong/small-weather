package handlers

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/smtp"
	"os"
	"strconv"
	"strings"
	"time"
)

type smtpConfig struct {
	Host      string
	Port      int
	Username  string
	Password  string
	FromEmail string
	FromName  string
}

func loadSMTPConfig() (smtpConfig, error) {
	port := 465
	if rawPort := strings.TrimSpace(os.Getenv("SMTP_PORT")); rawPort != "" {
		parsed, err := strconv.Atoi(rawPort)
		if err != nil {
			return smtpConfig{}, fmt.Errorf("invalid SMTP_PORT")
		}
		port = parsed
	}

	cfg := smtpConfig{
		Host:      strings.TrimSpace(os.Getenv("SMTP_HOST")),
		Port:      port,
		Username:  strings.TrimSpace(os.Getenv("SMTP_USERNAME")),
		Password:  strings.TrimSpace(os.Getenv("SMTP_PASSWORD")),
		FromEmail: strings.TrimSpace(os.Getenv("SMTP_FROM_EMAIL")),
		FromName:  strings.TrimSpace(os.Getenv("SMTP_FROM_NAME")),
	}

	if cfg.Host == "" || cfg.Username == "" || cfg.Password == "" || cfg.FromEmail == "" {
		return smtpConfig{}, fmt.Errorf("SMTP configuration is incomplete")
	}

	if cfg.FromName == "" {
		cfg.FromName = "Weather App"
	}

	return cfg, nil
}

func sendVerificationEmail(email, purpose, code string) error {
	cfg, err := loadSMTPConfig()
	if err != nil {
		return err
	}

	subject := "Weather App Verification Code"
	title := "Verification Code"
	actionText := "Use this code to continue."
	if purpose == "reset_password" {
		subject = "Weather App Password Reset Code"
		title = "Password Reset Code"
		actionText = "Use this code to reset your password."
	}

	htmlBody := fmt.Sprintf(`
<html>
  <body style="font-family: Arial, sans-serif; background:#f7f8fc; padding:24px;">
    <div style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:20px;padding:32px;border:1px solid #e8ebf4;">
      <h2 style="margin:0 0 12px;color:#1f2937;">%s</h2>
      <p style="margin:0 0 20px;color:#4b5563;line-height:1.6;">%s</p>
      <div style="font-size:32px;font-weight:700;letter-spacing:6px;color:#2563eb;margin:16px 0 24px;">%s</div>
      <p style="margin:0;color:#6b7280;line-height:1.6;">This code will expire in 10 minutes.</p>
    </div>
  </body>
</html>`, title, actionText, code)

	plainBody := fmt.Sprintf("%s\n\n%s\n\n%s\n\nThis code will expire in 10 minutes.", title, actionText, code)

	return sendSMTPMail(cfg, email, subject, plainBody, htmlBody)
}

func sendSMTPMail(cfg smtpConfig, toEmail, subject, plainBody, htmlBody string) error {
	addr := fmt.Sprintf("%s:%d", cfg.Host, cfg.Port)
	header := []string{
		fmt.Sprintf("From: %s <%s>", cfg.FromName, cfg.FromEmail),
		fmt.Sprintf("To: %s", toEmail),
		fmt.Sprintf("Subject: %s", subject),
		"MIME-Version: 1.0",
		`Content-Type: multipart/alternative; boundary="boundary-weather-app"`,
		"",
		"--boundary-weather-app",
		`Content-Type: text/plain; charset="UTF-8"`,
		"",
		plainBody,
		"--boundary-weather-app",
		`Content-Type: text/html; charset="UTF-8"`,
		"",
		htmlBody,
		"--boundary-weather-app--",
	}

	message := strings.Join(header, "\r\n")
	auth := smtp.PlainAuth("", cfg.Username, cfg.Password, cfg.Host)

	if cfg.Port == 465 {
		return sendWithImplicitTLS(addr, cfg, auth, toEmail, []byte(message))
	}

	return sendWithStartTLS(addr, cfg, auth, toEmail, []byte(message))
}

func sendWithImplicitTLS(addr string, cfg smtpConfig, auth smtp.Auth, toEmail string, message []byte) error {
	tlsConn, err := tls.DialWithDialer(
		&net.Dialer{Timeout: 10 * time.Second},
		"tcp",
		addr,
		&tls.Config{ServerName: cfg.Host},
	)
	if err != nil {
		return err
	}
	defer tlsConn.Close()

	client, err := smtp.NewClient(tlsConn, cfg.Host)
	if err != nil {
		return err
	}
	defer client.Quit()

	if err := client.Auth(auth); err != nil {
		return err
	}
	if err := client.Mail(cfg.FromEmail); err != nil {
		return err
	}
	if err := client.Rcpt(toEmail); err != nil {
		return err
	}

	writer, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := writer.Write(message); err != nil {
		_ = writer.Close()
		return err
	}
	return writer.Close()
}

func sendWithStartTLS(addr string, cfg smtpConfig, auth smtp.Auth, toEmail string, message []byte) error {
	client, err := smtp.Dial(addr)
	if err != nil {
		return err
	}
	defer client.Quit()

	if ok, _ := client.Extension("STARTTLS"); ok {
		if err := client.StartTLS(&tls.Config{ServerName: cfg.Host}); err != nil {
			return err
		}
	}
	if err := client.Auth(auth); err != nil {
		return err
	}
	if err := client.Mail(cfg.FromEmail); err != nil {
		return err
	}
	if err := client.Rcpt(toEmail); err != nil {
		return err
	}

	writer, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := writer.Write(message); err != nil {
		_ = writer.Close()
		return err
	}
	return writer.Close()
}
