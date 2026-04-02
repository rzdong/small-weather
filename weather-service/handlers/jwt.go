package handlers

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"
)

type jwtClaims struct {
	UserID    int    `json:"user_id"`
	UserEmail string `json:"user_email"`
	UserName  string `json:"user_name"`
	Exp       int64  `json:"exp"`
	Iat       int64  `json:"iat"`
}

func generateJWT(userID int, email, name string) (string, error) {
	header := map[string]string{"alg": "HS256", "typ": "JWT"}
	claims := jwtClaims{
		UserID:    userID,
		UserEmail: email,
		UserName:  name,
		Iat:       time.Now().Unix(),
		Exp:       time.Now().Add(30 * 24 * time.Hour).Unix(),
	}

	headerJSON, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	headerPart := base64.RawURLEncoding.EncodeToString(headerJSON)
	claimsPart := base64.RawURLEncoding.EncodeToString(claimsJSON)
	unsignedToken := headerPart + "." + claimsPart

	signature, err := signJWT(unsignedToken)
	if err != nil {
		return "", err
	}

	return unsignedToken + "." + signature, nil
}

func validateJWT(token string) (*jwtClaims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return nil, fmt.Errorf("invalid token format")
	}

	unsignedToken := parts[0] + "." + parts[1]
	expectedSignature, err := signJWT(unsignedToken)
	if err != nil {
		return nil, err
	}
	if !hmac.Equal([]byte(expectedSignature), []byte(parts[2])) {
		return nil, fmt.Errorf("invalid token signature")
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, fmt.Errorf("invalid token payload")
	}

	var claims jwtClaims
	if err := json.Unmarshal(payload, &claims); err != nil {
		return nil, fmt.Errorf("invalid token claims")
	}

	if claims.Exp <= time.Now().Unix() {
		return nil, fmt.Errorf("token expired")
	}

	return &claims, nil
}

func ValidateJWTForMiddleware(token string) (*jwtClaims, error) {
	return validateJWT(token)
}

func signJWT(unsignedToken string) (string, error) {
	secret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if secret == "" {
		return "", fmt.Errorf("JWT_SECRET is not configured in environment")
	}

	mac := hmac.New(sha256.New, []byte(secret))
	if _, err := mac.Write([]byte(unsignedToken)); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil)), nil
}
