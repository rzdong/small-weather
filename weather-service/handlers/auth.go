package handlers

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"
)

const verificationCodeTTL = 10 * time.Minute

type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type SendCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type VerifyCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
	Code  string `json:"code" binding:"required"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
	Code     string `json:"code" binding:"required"`
	Name     string `json:"name"`
}

type ResetPasswordCompleteRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Code        string `json:"code" binding:"required"`
	NewPassword string `json:"new_password" binding:"required"`
}

type UpdateProfileRequest struct {
	Name       string `json:"name"`
	UserAvatar string `json:"user_avatar"`
}

// 发送邮箱注册验证码
func SendRegisterCode(c *gin.Context) {
	var req SendCodeRequest
	// 先判断邮箱是否填写，没填写直接返回异常
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "A valid email is required"})
		return
	}

	var exists int
	err := DB.QueryRow("SELECT COUNT(*) FROM users WHERE email = ?", req.Email).Scan(&exists)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	if exists > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "This email is already registered"})
		return
	}

	if err := saveVerificationCode(req.Email, "register"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to send verification code"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Verification code sent"})
}

func Register(c *gin.Context) {
	var req RegisterRequest
	/** ShouldBindJSON 会自动校验请求体中的字段是否符合RegisterRequest的结构，如果 */
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email, password, and code are required"})
		return
	}

	if err := verifyCode(req.Email, "register", req.Code); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	passwordHash, err := hashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to secure password"})
		return
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		name = strings.Split(req.Email, "@")[0]
	}

	result, err := DB.Exec(
		"INSERT INTO users (email, password, name) VALUES (?, ?, ?)",
		req.Email,
		passwordHash,
		name,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "User already exists or DB error"})
		return
	}

	userID, _ := result.LastInsertId()
	if _, err := DB.Exec("INSERT INTO user_settings (user_id) VALUES (?)", userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to initialize settings"})
		return
	}

	if err := consumeVerificationCode(req.Email, "register", req.Code); err != nil {
		log.Println("consume register code error:", err)
	}

	token, err := generateJWT(int(userID), req.Email, name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "JWT error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"token":       token,
			"user_id":     userID,
			"email":       req.Email,
			"name":        name,
			"user_avatar": "",
		},
	})
}

func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email and password are required"})
		return
	}

	var u User
	var avatar sql.NullString
	err := DB.QueryRow(
		"SELECT id, email, password, name, user_avatar FROM users WHERE email = ?",
		req.Email,
	).Scan(&u.ID, &u.Email, &u.Password, &u.Name, &avatar)
	if err != nil {
		log.Println("login query error:", err)
		if err == sql.ErrNoRows {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Invalid credentials"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		}
		return
	}
	u.Avatar = avatar.String

	if err := comparePassword(u.Password, req.Password); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Invalid credentials"})
		return
	}

	token, err := generateJWT(u.ID, u.Email, u.Name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "JWT error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"token":       token,
			"user_id":     u.ID,
			"email":       u.Email,
			"name":        u.Name,
			"user_avatar": u.Avatar,
		},
	})
}

func SendResetPasswordCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "A valid email is required"})
		return
	}

	exists, err := userExists(req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "This email is not registered"})
		return
	}

	if err := saveVerificationCode(req.Email, "reset_password"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to send verification code"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Verification code sent"})
}

func VerifyResetPasswordCode(c *gin.Context) {
	var req VerifyCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email and code are required"})
		return
	}

	if err := verifyCode(req.Email, "reset_password", req.Code); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Verification code is valid"})
}

func ResetPassword(c *gin.Context) {
	var req ResetPasswordCompleteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email, code, and new password are required"})
		return
	}

	if err := verifyCode(req.Email, "reset_password", req.Code); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	passwordHash, err := hashPassword(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Failed to secure password"})
		return
	}

	result, err := DB.Exec("UPDATE users SET password = ? WHERE email = ?", passwordHash, req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "This email is not registered"})
		return
	}

	if err := consumeVerificationCode(req.Email, "reset_password", req.Code); err != nil {
		log.Println("consume reset code error:", err)
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Password reset successfully"})
}

func GetProfile(c *gin.Context) {
	userID := c.GetInt("userID")
	var u User
	var avatar sql.NullString
	err := DB.QueryRow(
		"SELECT id, email, name, user_avatar FROM users WHERE id = ?",
		userID,
	).Scan(&u.ID, &u.Email, &u.Name, &avatar)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}
	u.Avatar = avatar.String

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":          u.ID,
			"email":       u.Email,
			"name":        u.Name,
			"user_avatar": u.Avatar,
		},
	})
}

func UpdateProfile(c *gin.Context) {
	userID := c.GetInt("userID")
	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Invalid profile data"})
		return
	}

	var current User
	var currentAvatar sql.NullString
	err := DB.QueryRow(
		"SELECT id, email, name, user_avatar FROM users WHERE id = ?",
		userID,
	).Scan(&current.ID, &current.Email, &current.Name, &currentAvatar)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}
	current.Avatar = currentAvatar.String

	name := strings.TrimSpace(req.Name)
	if req.Name != "" && name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Name is required"})
		return
	}

	avatar := strings.TrimSpace(req.UserAvatar)
	if name == "" && avatar == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "No profile changes provided"})
		return
	}

	if name == "" {
		name = current.Name
	}
	if avatar == "" {
		avatar = current.Avatar
	}

	if _, err := DB.Exec(
		"UPDATE users SET name = ?, user_avatar = ? WHERE id = ?",
		name,
		avatar,
		userID,
	); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "DB error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":          userID,
			"email":       current.Email,
			"name":        name,
			"user_avatar": avatar,
		},
		"message": "Profile updated",
	})
}

func Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Logged out"})
}

func saveVerificationCode(email, purpose string) error {
	code := generateVerificationCode()
	key := fmt.Sprintf("vc:%s:%s", purpose, email)

	ctx := context.Background()
	err := Redis.Set(ctx, key, code, verificationCodeTTL).Err()
	if err != nil {
		return err
	}

	log.Printf("verification code [%s] for %s: %s (stored in Redis)", purpose, email, code)
	return sendVerificationEmail(email, purpose, code)
}

func verifyCode(email, purpose, code string) error {
	key := fmt.Sprintf("vc:%s:%s", purpose, email)
	ctx := context.Background()

	storedCode, err := Redis.Get(ctx, key).Result()
	if err == redis.Nil {
		return fmt.Errorf("Please send the verification code first")
	} else if err != nil {
		return fmt.Errorf("Redis error")
	}

	if strings.TrimSpace(storedCode) != strings.TrimSpace(code) {
		return fmt.Errorf("The verification code is incorrect")
	}

	return nil
}

func consumeVerificationCode(email, purpose, code string) error {
	key := fmt.Sprintf("vc:%s:%s", purpose, email)
	ctx := context.Background()
	return Redis.Del(ctx, key).Err()
}

// Removed MySQL-based cleanup scheduler as Redis handles TTL automatically.

func userExists(email string) (bool, error) {
	var exists int
	err := DB.QueryRow("SELECT COUNT(*) FROM users WHERE email = ?", email).Scan(&exists)
	return exists > 0, err
}

func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hash), err
}

func comparePassword(storedHash, password string) error {
	if strings.HasPrefix(storedHash, "$2") {
		return bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
	}

	if storedHash == password {
		return nil
	}

	return bcrypt.ErrMismatchedHashAndPassword
}

func generateVerificationCode() string {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%06d", rng.Intn(1000000))
}
